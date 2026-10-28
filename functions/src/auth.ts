import { HttpsError, CallableRequest } from 'firebase-functions/v2/https';

/** Comma-separated bootstrap list; kept server-side only (functions/.env). */
export const superAdmins = (): string[] =>
  (process.env.SUPER_ADMINS || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);

export const isSuperAdmin = (email?: string): boolean =>
  !!email && superAdmins().includes(email.toLowerCase());

/** Throws unless the caller has the `admin` claim or is a bootstrap super admin. */
export function requireAdmin(request: CallableRequest): { uid: string; email: string } {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be authenticated');
  }
  const email = (request.auth.token.email as string | undefined) || '';
  const isAdmin = request.auth.token.admin === true || isSuperAdmin(email);
  if (!isAdmin) {
    throw new HttpsError('permission-denied', 'You are not an admin');
  }
  return { uid: request.auth.uid, email };
}
