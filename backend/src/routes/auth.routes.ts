import { Router } from 'express';
import { signUserToken } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { calculateDailyGoalCalories } from '../services/calorieService';
import {
  hashPassword,
  isValidEmail,
  MIN_PASSWORD_LENGTH,
  normalizeEmail,
  verifyPassword,
} from '../services/passwordService';
import { ApiError } from '../utils/ApiError';
import { asyncHandler } from '../utils/asyncHandler';

export const authRouter = Router();

/**
 * @openapi
 * /auth/signup:
 *   post:
 *     tags: [Auth]
 *     summary: 회원가입
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, gender, age, height, weight, activity_level]
 *             properties:
 *               email: { type: string, example: bread@example.com, description: '앱 1.1.0+ 필수. 1.0.0 호환을 위해 서버에서는 선택(보내면 password도 필수)' }
 *               password: { type: string, minLength: 8 }
 *               name: { type: string }
 *               gender: { type: string, example: F }
 *               age: { type: integer, example: 28 }
 *               height: { type: number, example: 162 }
 *               weight: { type: number, example: 55 }
 *               activity_level: { type: string, enum: ['여행 휴식', '관광', '도보여행'] }
 *     responses:
 *       201:
 *         description: 가입 성공, JWT 토큰 발급
 *       400:
 *         description: 필수 값 누락 / 이메일 형식 오류 / 비밀번호 8자 미만
 *       409:
 *         description: 이미 가입된 이메일 (EMAIL_TAKEN)
 */
// POST /api/auth/signup — legacy/ppangkal.md §12.1
authRouter.post(
  '/signup',
  asyncHandler(async (req, res) => {
    const { name, gender, age, height, weight, activity_level: activityLevel, email: rawEmail, password } = req.body;

    if (!name || !gender || !age || !height || !weight || !activityLevel) {
      throw ApiError.badRequest('name, gender, age, height, weight, activity_level은 필수 값입니다.');
    }

    // 이미 설치된 1.0.0 앱은 email/password 없이 가입하므로 서버는 둘 다 없는 요청도 받는다.
    let credentials: { email: string; passwordHash: string } | undefined;
    if (rawEmail !== undefined || password !== undefined) {
      if (typeof rawEmail !== 'string' || typeof password !== 'string') {
        throw ApiError.badRequest('email과 password는 함께 보내야 합니다.');
      }
      const email = normalizeEmail(rawEmail);
      if (!isValidEmail(email)) throw ApiError.badRequest('이메일 형식이 올바르지 않습니다.');
      if (password.length < MIN_PASSWORD_LENGTH) {
        throw ApiError.badRequest(`비밀번호는 ${MIN_PASSWORD_LENGTH}자 이상이어야 합니다.`);
      }
      if (await prisma.user.findUnique({ where: { email } })) {
        throw new ApiError(409, 'EMAIL_TAKEN', '이미 가입된 이메일입니다.');
      }
      credentials = { email, passwordHash: await hashPassword(password) };
    }

    const dailyGoalCalories = calculateDailyGoalCalories({ gender, weightKg: weight, heightCm: height, age, activityLevel });

    const user = await prisma.user.create({
      data: { name, gender, age, height, weight, activityLevel, dailyGoalCalories, ...credentials },
    });

    res.status(201).json({
      user: { id: user.id, name: user.name, daily_goal_calories: user.dailyGoalCalories },
      token: signUserToken(user.id),
    });
  }),
);

/**
 * @openapi
 * /auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: 로그인 — email+password (권장) 또는 user_id (1.0.0 호환)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *               user_id: { type: string, description: 'email 없이 보낼 때만 사용하는 기존 ID 로그인' }
 *     responses:
 *       200:
 *         description: JWT 토큰 발급
 *       400:
 *         description: email/password 또는 user_id 누락
 *       401:
 *         description: 이메일 또는 비밀번호 불일치 (INVALID_CREDENTIALS)
 *       404:
 *         description: 사용자 없음 (user_id 로그인)
 */
// POST /api/auth/login
authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { email: rawEmail, password, user_id: userId } = req.body;

    if (rawEmail !== undefined) {
      if (typeof rawEmail !== 'string' || typeof password !== 'string' || !password) {
        throw ApiError.badRequest('email과 password는 필수 값입니다.');
      }
      const user = await prisma.user.findUnique({ where: { email: normalizeEmail(rawEmail) } });
      // 가입 여부를 노출하지 않도록 이메일 없음/비밀번호 불일치를 같은 응답으로 돌려준다.
      if (!user?.passwordHash || !(await verifyPassword(password, user.passwordHash))) {
        throw new ApiError(401, 'INVALID_CREDENTIALS', '이메일 또는 비밀번호가 올바르지 않습니다.');
      }
      res.json({ token: signUserToken(user.id) });
      return;
    }

    if (!userId) throw ApiError.badRequest('email과 password는 필수 값입니다.');

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw ApiError.notFound('사용자를 찾을 수 없습니다.');

    res.json({ token: signUserToken(user.id) });
  }),
);
