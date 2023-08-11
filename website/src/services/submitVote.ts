import { fetchConfig } from "./fetchConfig";

export const submitVote = async (winner: string, loser: string) => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/selectWinner", {
    method: "POST",
    body: JSON.stringify({ winner, loser }),
  });
  if (!response.ok) {
    console.error("Failed to submit vote");
  }
  const jsonData: { winner: number; loser: number } = await response.json();
  return jsonData;
};
