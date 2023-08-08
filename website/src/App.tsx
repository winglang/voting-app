import React, { useState, useEffect } from "react";

interface Config {
  baseUrl: string;
}

interface Entry {
  name: string;
  score: number;
}

interface LeaderboardProps {
  swapViews: () => void;
}

const fetchConfig = async () => {
  const response = await fetch("./config.json");
  if (!response.ok) {
    throw new Error('Failed to fetch config');
  }
  const config: Config = await response.json();
  return config;
}

const fetchItems = async () => {
  const baseUrl = (await fetchConfig()).baseUrl;
  const response = await fetch(baseUrl + "/items");
  if (!response.ok) {
    throw new Error('Failed to fetch leaderboard data');
  }
  const jsonData: Entry[] = await response.json();
  return jsonData;
}

const fetchChoices = async () => {
  const baseUrl = (await fetchConfig()).baseUrl;
  const response = await fetch(baseUrl + "/requestChoices", {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error('Failed to request choices');
  }
  const jsonData: string[] = await response.json();
  return jsonData;
}

const Leaderboard = (props: LeaderboardProps) => {
  const [data, setData] = useState<Entry[]>([]);
  useEffect(() => {
    fetchItems().then((items) => setData(items));
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
          {data.sort((a, b) => b.score - a.score).map((item) => (
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
  useEffect(() => {
    fetchChoices().then((choices) => setChoices(choices));
  }, []);

  return (
    <div>
      <h2>Which is better?</h2>
      <div className="choices">
        {choices.map((item) => (
          <div key={item} className="choice">
            <div className="name">{item}</div>
            <button className="button">Vote</button>
          </div>
        ))}
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
