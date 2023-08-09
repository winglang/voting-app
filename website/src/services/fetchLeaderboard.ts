import { fetchConfig } from "./fetchConfig";

export interface Entry {
  name: string;
  score: number;
}

export const fetchLeaderboard = async () => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/leaderboard");
  if (!response.ok) {
    throw new Error("Failed to fetch leaderboard data");
  }
  const jsonData: Entry[] = await response.json();
  return jsonData;
};
