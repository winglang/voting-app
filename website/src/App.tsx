import React, { useState, useEffect } from "react";

interface Config {
  apiUrl: string;
}

interface Entry {
  name: string;
  score: number;
}

const fetchConfig = async () => {
  const response = await fetch("./config.json");
  if (!response.ok) {
    throw new Error('Failed to fetch config');
  }
  const config: Config = await response.json();
  return config;
}

const fetchLeaderboard = async () => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/leaderboard");
  if (!response.ok) {
    throw new Error('Failed to fetch leaderboard data');
  }
  const jsonData: Entry[] = await response.json();
  return jsonData;
}

const fetchChoices = async () => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/requestChoices", {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error('Failed to request choices');
  }
  const jsonData: string[] = await response.json();
  return jsonData;
}

const submitVote = async (winner: string, loser: string) => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/selectWinner", {
    method: "POST",
    body: JSON.stringify({ winner, loser }),
  });
  if (!response.ok) {
    console.error('Failed to submit vote');
  }
  const jsonData: { winner: number; loser: number; } = await response.json();
  return jsonData;
}

interface LeaderboardProps {
  swapViews: () => void;
}

const Leaderboard = (props: LeaderboardProps) => {
  const [entries, setEntries] = useState<Entry[]>([]);
  useEffect(() => {
    fetchLeaderboard().then((items) => setEntries(items));
  }, []);

  return (
    <div>
      <h2>Leaderboard</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Score</th>
          </tr>
        </thead>
        <tbody>
          {entries.sort((a, b) => b.score - a.score).map((item) => (
            <tr key={item.name}>
              <td>{item.name}</td>
              <td>{item.score}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <button onClick={props.swapViews}>Back</button>
    </div>
  );
};

interface VotingProps {
  swapViews: () => void;
}

const Voting = (props: VotingProps) => {
  const [choices, setChoices] = useState<string[]>([]);
  const [scores, setScores] = useState<(number | null)[]>([null, null]);
  useEffect(() => {
    fetchChoices().then((choices) => setChoices(choices));
  }, []);

  const [winner, setWinner] = useState<string | null>(null);
  const selectWinner = async (winner: string, loser: string) => {
    const { winner: winnerScore, loser: loserScore } = await submitVote(winner, loser);
    if (winner === choices[0]) {
      setScores([winnerScore, loserScore]);
    } else {
      setScores([loserScore, winnerScore]);
    }
    setWinner(winner);
  };

  const reset = async () => {
    setWinner(null);
    setScores([null, null]);
    const choices = await fetchChoices();
    setChoices(choices);
  };

  const renderVoteButtonOrOutcome = (idx: number) => {
    if (winner === null) {
      return <button onClick={() => selectWinner(choices[idx], choices[1 - idx])}>Vote</button>;
    }
    return <p>{winner === choices[idx] ? "Winner" : "Loser"} (new score: {scores[idx]})</p>
  }

  return (
    <div>
      <h2>Which is better?</h2>
      <div className="choices">
        <div className="choice1">
          <h3 className="name">{choices[0]}</h3>
          {renderVoteButtonOrOutcome(0)}
        </div>
        <div className="choice2">
          <h3 className="name">{choices[1]}</h3>
          {renderVoteButtonOrOutcome(1)}
        </div>
        {
          winner !== null && (
            <button onClick={() => reset()}>Next matchup</button>
          )
        }
      </div>
      <button onClick={props.swapViews}>Leaderboard</button>
    </div>
  )
}

type View = "voting" | "leaderboard";

function App() {
  let [view, setView] = useState<View>("voting");
  const swapViews = () => {
    setView(view === "voting" ? "leaderboard" : "voting");
  };

  switch (view) {
    case "voting":
      return <Voting swapViews={swapViews} />;
    case "leaderboard":
      return <Leaderboard swapViews={swapViews} />;
  }
}

export default App;
