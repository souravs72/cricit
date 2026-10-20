import type { Context } from "hono";
import type { ContentfulStatusCode } from "hono/utils/http-status";

/** One error hierarchy, one JSON shape: {"error": {code, message, request_id, field?}}. */
export class AppError extends Error {
  readonly status: ContentfulStatusCode = 400;
  readonly code: string = "bad_request";
  constructor(
    message: string,
    readonly field?: string,
  ) {
    super(message);
  }
}
export class Unauthorized extends AppError {
  override readonly status = 401;
  override readonly code = "unauthorized";
}
export class Forbidden extends AppError {
  override readonly status = 403;
  override readonly code = "forbidden";
}
export class NotFound extends AppError {
  override readonly status = 404;
  override readonly code = "not_found";
}
export class Conflict extends AppError {
  override readonly status = 409;
  override readonly code = "conflict";
}
export class ValidationFailed extends AppError {
  override readonly status = 422;
  override readonly code = "validation_failed";
}
export class RateLimited extends AppError {
  override readonly status = 429;
  override readonly code = "rate_limited";
}
export class NotBuiltYet extends AppError {
  override readonly status = 501;
  override readonly code = "not_implemented";
}

export function errorBody(c: Context, code: string, message: string, field?: string) {
  return {
    error: { code, message, request_id: c.get("requestId") as string | undefined, ...(field ? { field } : {}) },
  };
}

export function onError(err: Error, c: Context) {
  // A route may already have set a public Cache-Control; an error must never be cached at the edge.
  c.header("Cache-Control", "no-store");
  if (err instanceof AppError) {
    return c.json(errorBody(c, err.code, err.message, err.field), err.status);
  }
  // Unknown error: log with the request id, never leak details to the client.
  console.error(
    JSON.stringify({
      level: "error",
      event: "unhandled_error",
      request_id: c.get("requestId"),
      path: c.req.path,
      name: err.name,
      message: err.message,
      stack: err.stack,
    }),
  );
  return c.json(errorBody(c, "internal_error", "Something went wrong. Quote the request ID."), 500);
}
