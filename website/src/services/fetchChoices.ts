import { fetchConfig } from "./fetchConfig";

export const fetchChoices = async () => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/requestChoices", {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error("Failed to request choices");
  }
  const jsonData: string[] = await response.json();
  return jsonData;
};
