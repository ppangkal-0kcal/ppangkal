import cors from 'cors';
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { apiRouter } from './routes';
import { errorHandler } from './middleware/errorHandler';
import { swaggerSpec } from './config/swagger';

export const app = express();

// Open CORS: auth is JWT-bearer (Authorization header), not cookie-based,
// so there's no session to leak cross-origin — safe to allow any origin
// for the Flutter web dev target (its dev-server port varies per run).
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use('/api', apiRouter);

app.use(errorHandler);
