import type { FastifyInstance } from "fastify";
import { authRoutes } from "./auth.js";
import { courseRoutes } from "./courses.js";
import { challengeRoutes } from "./challenges.js";
import { progressRoutes } from "./progress.js";
import { leaderboardRoutes } from "./leaderboard.js";
import { credentialRoutes } from "./credentials.js";
import { adminRoutes } from "./admin.js";
import { streakRoutes } from "./streak.js";
import { achievementRoutes } from "./achievements.js";
import { internalJobRoutes } from "./internal-jobs.js";
import { userRoutes } from "./user.js";
import { prisma } from "../lib/prisma.js";

export async function registerRoutes(app: FastifyInstance): Promise<void> {
  app.get("/health", async (_request, reply) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      return { status: "ok", database: "ok" };
    } catch {
      reply.code(503);
      return { status: "degraded", database: "unavailable" };
    }
  });

  await app.register(
    async (v1) => {
      await authRoutes(v1);
      await courseRoutes(v1);
      await challengeRoutes(v1);
      await progressRoutes(v1);
      await streakRoutes(v1);
      await leaderboardRoutes(v1);
      await credentialRoutes(v1);
      await achievementRoutes(v1);
      await userRoutes(v1);
      await internalJobRoutes(v1);
      await v1.register(adminRoutes);
    },
    { prefix: "/v1" },
  );
}
