// Set EXPO_PUBLIC_API_URL to the deployed HTTPS API URL when building.
// There is deliberately no private-LAN fallback: it cannot work off the user's Wi-Fi.
const configuredUrl = process.env.EXPO_PUBLIC_API_URL;
export const API_URL = configuredUrl ? configuredUrl.replace(/\/$/, '') : '';
export const API_CONFIGURED = /^https:\/\//i.test(API_URL);
