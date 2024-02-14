export interface Config {
  apiUrl: string;
}

let cachedConfig: Config | null = null;

export const fetchConfig = async () => {
  // In production, use the cached config if available
  if (process.env.NODE_ENV === 'production' && cachedConfig) {
    return cachedConfig;
  }

  const response = await fetch("./config.json");
  if (!response.ok) {
    throw new Error("Failed to fetch config");
  }
  const config: Config = await response.json();

  // Cache the config if in production mode
  if (process.env.NODE_ENV === 'production') {
    cachedConfig = config;
  }

  return config;
};
