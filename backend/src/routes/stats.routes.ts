import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { ApiError } from '../utils/ApiError';
import { asyncHandler } from '../utils/asyncHandler';

export const statsRouter = Router();
statsRouter.use(requireAuth);

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function endOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(23, 59, 59, 999);
  return d;
}

/**
 * @openapi
 * /stats/daily:
 *   get:
 *     tags: [Stats]
 *     summary: 일별 칼로리 통계
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: date
 *         schema: { type: string, format: date }
 *     responses:
 *       200:
 *         description: "date, consumed_calories, burned_calories, goal_calories, bakeries_visited, visits[] — 그날 방문한 빵집(진행 중 투어 포함)별 { tour_stop_id, bakery_id, bakery_name, visited_at, calories_burned, breads: [{ bread_item_id(직접 입력이면 null), name, is_custom, quantity, calories }] }"
 *       404:
 *         description: 사용자 없음
 */
// GET /api/stats/daily — legacy/ppangkal.md §12.8
statsRouter.get(
  '/daily',
  asyncHandler(async (req, res) => {
    const date = req.query.date ? new Date(String(req.query.date)) : new Date();
    const from = startOfDay(date);
    const to = endOfDay(date);

    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) throw ApiError.notFound('사용자를 찾을 수 없습니다.');

    const [foodLogs, tours, stops] = await Promise.all([
      prisma.foodLog.findMany({ where: { userId: req.userId, loggedAt: { gte: from, lte: to } } }),
      prisma.tour.findMany({
        where: { userId: req.userId, completedAt: { gte: from, lte: to } },
        include: { stops: true },
      }),
      // 진행 중인 투어의 방문도 포함한다 — 통계 탭에서 "오늘 고른 빵집과 빵"을 바로 보여주기 위함.
      prisma.tourStop.findMany({
        where: { tour: { userId: req.userId }, visitedAt: { gte: from, lte: to } },
        include: { bakery: true, foodLogs: { include: { breadItem: true } } },
        orderBy: { visitedAt: 'asc' },
      }),
    ]);

    const consumedCalories = foodLogs.reduce((sum, log) => sum + log.calories * log.quantity, 0);
    const burnedCalories = tours.reduce((sum, tour) => sum + (tour.totalCaloriesBurned ?? 0), 0);
    const bakeriesVisited = new Set(tours.flatMap((tour) => tour.stops.map((stop) => stop.bakeryId))).size;

    res.json({
      date: from.toISOString().slice(0, 10),
      consumed_calories: consumedCalories,
      burned_calories: burnedCalories,
      goal_calories: user.dailyGoalCalories,
      bakeries_visited: bakeriesVisited,
      visits: stops.map((stop) => ({
        tour_stop_id: stop.id,
        bakery_id: stop.bakeryId,
        bakery_name: stop.bakery.name,
        visited_at: stop.visitedAt.toISOString(),
        calories_burned: stop.caloriesBurned,
        breads: stop.foodLogs.map((log) => ({
          bread_item_id: log.breadItemId,
          name: log.breadItem?.name ?? log.customName ?? '직접 입력한 빵',
          is_custom: log.breadItemId === null,
          quantity: log.quantity,
          calories: log.calories * log.quantity,
        })),
      })),
    });
  }),
);

/**
 * @openapi
 * /stats/weekly:
 *   get:
 *     tags: [Stats]
 *     summary: 주간 칼로리 통계 (최근 7일)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: to
 *         schema: { type: string, format: date }
 *     responses:
 *       200:
 *         description: days[], goal_achievement_rate
 *       404:
 *         description: 사용자 없음
 */
// GET /api/stats/weekly — legacy/ppangkal.md §12.8
statsRouter.get(
  '/weekly',
  asyncHandler(async (req, res) => {
    const to = req.query.to ? new Date(String(req.query.to)) : new Date();
    const from = startOfDay(new Date(to.getTime() - 6 * 24 * 60 * 60 * 1000));

    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) throw ApiError.notFound('사용자를 찾을 수 없습니다.');

    const [foodLogs, tours] = await Promise.all([
      prisma.foodLog.findMany({ where: { userId: req.userId, loggedAt: { gte: from, lte: endOfDay(to) } } }),
      prisma.tour.findMany({ where: { userId: req.userId, completedAt: { gte: from, lte: endOfDay(to) } } }),
    ]);

    const days: { date: string; consumed_calories: number; burned_calories: number }[] = [];
    for (let i = 0; i < 7; i += 1) {
      const day = new Date(from.getTime() + i * 24 * 60 * 60 * 1000);
      const dayStart = startOfDay(day);
      const dayEnd = endOfDay(day);

      const consumed = foodLogs
        .filter((log) => log.loggedAt >= dayStart && log.loggedAt <= dayEnd)
        .reduce((sum, log) => sum + log.calories * log.quantity, 0);
      const burned = tours
        .filter((tour) => tour.completedAt && tour.completedAt >= dayStart && tour.completedAt <= dayEnd)
        .reduce((sum, tour) => sum + (tour.totalCaloriesBurned ?? 0), 0);

      days.push({ date: dayStart.toISOString().slice(0, 10), consumed_calories: consumed, burned_calories: burned });
    }

    const daysUnderGoal = days.filter((day) => day.consumed_calories - day.burned_calories <= user.dailyGoalCalories).length;

    res.json({ days, goal_achievement_rate: Math.round((daysUnderGoal / 7) * 100) });
  }),
);
