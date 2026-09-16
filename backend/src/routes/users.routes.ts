import { Router } from 'express';
import { requireAuth } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { hashPassword, isValidEmail, MIN_PASSWORD_LENGTH, normalizeEmail } from '../services/passwordService';
import { ApiError } from '../utils/ApiError';
import { asyncHandler } from '../utils/asyncHandler';

export const usersRouter = Router();
usersRouter.use(requireAuth);

/**
 * @openapi
 * /users/me:
 *   get:
 *     tags: [Users]
 *     summary: 내 프로필 조회
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: 프로필 정보
 *       404:
 *         description: 사용자 없음
 */
// GET /api/users/me — legacy/ppangkal.md §12.2
usersRouter.get(
  '/me',
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) throw ApiError.notFound('사용자를 찾을 수 없습니다.');

    res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      gender: user.gender,
      age: user.age,
      height: user.height,
      weight: user.weight,
      activity_level: user.activityLevel,
      daily_goal_calories: user.dailyGoalCalories,
    });
  }),
);

/**
 * @openapi
 * /users/me/credentials:
 *   put:
 *     tags: [Users]
 *     summary: 기존 ID 로그인 사용자에게 이메일+비밀번호 로그인 연결 (아직 이메일이 없는 계정만)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string }
 *               password: { type: string, minLength: 8 }
 *     responses:
 *       200:
 *         description: "{ email }"
 *       400:
 *         description: 형식 오류 / 이미 이메일이 연결된 계정 (EMAIL_ALREADY_SET)
 *       409:
 *         description: 다른 계정이 쓰는 이메일 (EMAIL_TAKEN)
 */
// PUT /api/users/me/credentials — 1.0.0 때 ID로만 가입한 사용자가 이메일 로그인으로 옮겨가는 경로
usersRouter.put(
  '/me/credentials',
  asyncHandler(async (req, res) => {
    const { email: rawEmail, password } = req.body;
    if (typeof rawEmail !== 'string' || typeof password !== 'string') {
      throw ApiError.badRequest('email과 password는 필수 값입니다.');
    }
    const email = normalizeEmail(rawEmail);
    if (!isValidEmail(email)) throw ApiError.badRequest('이메일 형식이 올바르지 않습니다.');
    if (password.length < MIN_PASSWORD_LENGTH) {
      throw ApiError.badRequest(`비밀번호는 ${MIN_PASSWORD_LENGTH}자 이상이어야 합니다.`);
    }

    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) throw ApiError.notFound('사용자를 찾을 수 없습니다.');
    // 이미 연결된 이메일/비밀번호 변경은 본인 확인 절차가 없어 여기서 허용하지 않는다.
    if (user.email) throw ApiError.badRequest('이미 이메일이 연결된 계정입니다.', 'EMAIL_ALREADY_SET');
    if (await prisma.user.findUnique({ where: { email } })) {
      throw new ApiError(409, 'EMAIL_TAKEN', '이미 가입된 이메일입니다.');
    }

    const updated = await prisma.user.update({
      where: { id: user.id },
      data: { email, passwordHash: await hashPassword(password) },
    });
    res.json({ email: updated.email });
  }),
);

/**
 * @openapi
 * /users/me:
 *   patch:
 *     tags: [Users]
 *     summary: 내 프로필 부분 수정 (체중/키/나이/활동량/목표 칼로리)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               weight: { type: number }
 *               height: { type: number }
 *               age: { type: integer }
 *               activity_level: { type: string, enum: ['여행 휴식', '관광', '도보여행'] }
 *               daily_goal_calories: { type: integer }
 *     responses:
 *       200:
 *         description: 수정된 프로필
 */
// PATCH /api/users/me — 체중/활동량/목표 칼로리 등 부분 수정
usersRouter.patch(
  '/me',
  asyncHandler(async (req, res) => {
    const { weight, height, age, activity_level: activityLevel, daily_goal_calories: dailyGoalCalories } = req.body;

    const user = await prisma.user.update({
      where: { id: req.userId },
      data: {
        ...(weight !== undefined && { weight }),
        ...(height !== undefined && { height }),
        ...(age !== undefined && { age }),
        ...(activityLevel !== undefined && { activityLevel }),
        ...(dailyGoalCalories !== undefined && { dailyGoalCalories }),
      },
    });

    res.json({
      id: user.id,
      weight: user.weight,
      height: user.height,
      age: user.age,
      activity_level: user.activityLevel,
      daily_goal_calories: user.dailyGoalCalories,
    });
  }),
);
