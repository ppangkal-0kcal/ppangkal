import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { ApiError } from '../utils/ApiError';
import { asyncHandler } from '../utils/asyncHandler';

export const foodLogsRouter = Router();
foodLogsRouter.use(requireAuth);

/**
 * @openapi
 * /food-logs:
 *   post:
 *     tags: [FoodLogs]
 *     summary: 섭취 기록 생성
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               bread_item_id: { type: string, description: '큐레이션된 메뉴를 먹은 경우' }
 *               custom_name: { type: string, description: 'DB에 없는 빵을 직접 입력한 경우 (custom_calories와 함께)' }
 *               custom_calories: { type: integer, description: '1개당 칼로리 (0~5000)' }
 *               tour_stop_id: { type: string, nullable: true }
 *               quantity: { type: integer, default: 1 }
 *     responses:
 *       201:
 *         description: 생성된 섭취 기록
 *       400:
 *         description: bread_item_id도 custom_name/custom_calories도 없음, 또는 값 범위 오류
 *       404:
 *         description: 빵 메뉴 또는 tour_stop_id를 찾을 수 없음
 */
// POST /api/food-logs — idea.md §2 7단계 (실제 섭취 시점에만 생성 — 예상치는 저장하지 않음)
foodLogsRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const {
      bread_item_id: breadItemId,
      custom_name: customNameRaw,
      custom_calories: customCalories,
      tour_stop_id: tourStopId,
      quantity = 1,
    } = req.body as {
      bread_item_id?: string;
      custom_name?: string;
      custom_calories?: number;
      tour_stop_id?: string | null;
      quantity?: number;
    };

    // 메뉴에 없는 빵은 사용자가 이름과 칼로리를 직접 입력한다 — 이 경우 bread_items에는 아무것도
    // 만들지 않는다 (큐레이션 데이터에 사용자 추정치가 섞이지 않도록).
    let entry: { breadItemId?: string; customName?: string; calories: number };
    if (breadItemId) {
      const breadItem = await prisma.breadItem.findUnique({ where: { id: breadItemId } });
      if (!breadItem) throw ApiError.notFound('빵 메뉴를 찾을 수 없습니다.');
      entry = { breadItemId, calories: breadItem.calories };
    } else {
      const customName = customNameRaw?.trim();
      if (!customName || typeof customCalories !== 'number') {
        throw ApiError.badRequest('bread_item_id, 또는 custom_name과 custom_calories가 필요합니다.');
      }
      if (customName.length > 50) throw ApiError.badRequest('빵 이름은 50자 이하여야 합니다.');
      if (!Number.isInteger(customCalories) || customCalories < 0 || customCalories > 5000) {
        throw ApiError.badRequest('custom_calories는 0~5000 사이의 정수여야 합니다.');
      }
      entry = { customName, calories: customCalories };
    }

    if (tourStopId) {
      const tourStop = await prisma.tourStop.findUnique({ where: { id: tourStopId } });
      if (!tourStop) throw ApiError.notFound('tour_stop_id를 찾을 수 없습니다.');
    }

    const foodLog = await prisma.foodLog.create({
      data: {
        userId: req.userId!,
        ...entry,
        tourStopId: tourStopId ?? undefined,
        quantity,
      },
    });

    res.status(201).json({
      id: foodLog.id,
      bread_item_id: foodLog.breadItemId,
      custom_name: foodLog.customName,
      tour_stop_id: foodLog.tourStopId,
      calories: foodLog.calories,
      quantity: foodLog.quantity,
      logged_at: foodLog.loggedAt,
    });
  }),
);

/**
 * @openapi
 * /food-logs:
 *   get:
 *     tags: [FoodLogs]
 *     summary: 섭취 기록 조회 (기간 필터)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: from
 *         schema: { type: string, format: date-time }
 *       - in: query
 *         name: to
 *         schema: { type: string, format: date-time }
 *     responses:
 *       200:
 *         description: 섭취 기록 목록
 */
// GET /api/food-logs — legacy/ppangkal.md §12.7
foodLogsRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const from = req.query.from ? new Date(String(req.query.from)) : new Date(new Date().setHours(0, 0, 0, 0));
    const to = req.query.to ? new Date(String(req.query.to)) : new Date();

    const foodLogs = await prisma.foodLog.findMany({
      where: { userId: req.userId, loggedAt: { gte: from, lte: to } },
      orderBy: { loggedAt: 'desc' },
    });

    res.json({
      food_logs: foodLogs.map((log) => ({
        id: log.id,
        bread_item_id: log.breadItemId,
        custom_name: log.customName,
        tour_stop_id: log.tourStopId,
        calories: log.calories,
        quantity: log.quantity,
        logged_at: log.loggedAt,
      })),
    });
  }),
);
