export type UserRole =
  | 'MANNING'
  | 'MANNING_RESTRICTED'
  | 'DOCUMENTATION'
  | 'ADMIN'
  | 'SUPERADMIN'
  | 'PRINCIPAL'
  | 'VESSEL_OWNER'
  | 'APPLICANT';

export interface RoleCredentials {
  username?: string;
  password?: string;
}

export function getCredentialsForRole(role: UserRole): RoleCredentials {
  switch (role) {
    case 'MANNING':
      return {
        username: process.env.UMMI_MANNING_USER,
        password: process.env.UMMI_MANNING_PASSWORD,
      };
    case 'MANNING_RESTRICTED':
      return {
        username: process.env.QA_C2_MANNING_RESTRICTED_USER || process.env.UMMI_MANNING_RESTRICTED_USER,
        password: process.env.QA_C2_MANNING_RESTRICTED_PASSWORD || process.env.UMMI_MANNING_RESTRICTED_PASSWORD,
      };
    case 'DOCUMENTATION':
      return {
        username: process.env.UMMI_DOCUMENTATION_USER,
        password: process.env.UMMI_DOCUMENTATION_PASSWORD,
      };
    case 'ADMIN':
      return {
        username: process.env.UMMI_ADMIN_USER,
        password: process.env.UMMI_ADMIN_PASSWORD,
      };
    case 'SUPERADMIN':
      return {
        username: process.env.UMMI_SUPERADMIN_USER,
        password: process.env.UMMI_SUPERADMIN_PASSWORD,
      };
    case 'PRINCIPAL':
      return {
        username: process.env.QA_C2_PRINCIPAL_USER || process.env.UMMI_PRINCIPAL_USER,
        password: process.env.QA_C2_PRINCIPAL_PASSWORD || process.env.UMMI_PRINCIPAL_PASSWORD,
      };
    case 'VESSEL_OWNER':
      return {
        username: process.env.QA_C2_VESSEL_OWNER_USER || process.env.UMMI_OWNER_USER,
        password: process.env.QA_C2_VESSEL_OWNER_PASSWORD || process.env.UMMI_OWNER_PASSWORD,
      };
    case 'APPLICANT':
      return {
        username: process.env.UMMI_APPLICANT_USER,
        password: process.env.UMMI_APPLICANT_PASSWORD,
      };
    default:
      return {};
  }
}
