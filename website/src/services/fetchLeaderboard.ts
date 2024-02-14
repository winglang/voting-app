import { useEffect, useRef, useState } from "react";
import { fetchConfig } from "./fetchConfig";

export interface Entry {
  name: string;
  score: number;
}

const fetchLeaderboard = async () => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/leaderboard");
  if (!response.ok) {
    throw new Error("Failed to fetch leaderboard data");
  }
  const jsonData: Entry[] = await response.json();
  return jsonData;
};

export const useFetchLeaderboard = () => {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Prevent automatic second fetch in development mode
  const hasFetchedInitialEntries = useRef(false);

  useEffect(() => {
    const fetchEntries = async () => {
      if (!hasFetchedInitialEntries.current) {
        hasFetchedInitialEntries.current = true;
        setIsLoading(true);
        try {
          const data = await fetchLeaderboard();
          setEntries(data);
        } finally {
          setIsLoading(false);
        }
      }
    };

    fetchEntries();
  }, []);

  return { entries, isLoading };
};
