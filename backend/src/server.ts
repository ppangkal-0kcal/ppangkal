import { app } from './app';
import { env } from './config/env';
import { prisma } from './lib/prisma';

const server = app.listen(env.port, () => {
  console.log(`빵칼 백엔드 서버 실행 중: http://localhost:${env.port}`);
});

// Hosting platforms (Render, Railway, Fly …) send SIGTERM on redeploy/scale-down.
// Stop accepting connections, let in-flight requests finish, then release the
// Supabase pooler connections instead of leaving them to time out.
function shutdown(signal: string) {
  console.log(`${signal} 수신 — 서버 종료 중`);
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
  // Don't hang forever on a stuck keep-alive connection.
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
