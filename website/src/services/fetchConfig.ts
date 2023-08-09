export interface Config {
  apiUrl: string;
}

export const fetchConfig = async () => {
  const response = await fetch("./config.json");
  if (!response.ok) {
    throw new Error("Failed to fetch config");
  }
  const config: Config = await response.json();
  return config;
};
