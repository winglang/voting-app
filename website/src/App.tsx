import { useState } from "react";
import { LeaderboardView } from "./views/LeaderboardView";
import { VotingView } from "./views/VotingView";
import { Button } from "./components/Button";

type View = "voting" | "leaderboard";

function App() {
  let [view, setView] = useState<View>("voting");

  const swapViews = () => {
    setView(view === "voting" ? "leaderboard" : "voting");
  };

  return (
    <div className="App absolute inset-0">
      <div className="w-full h-full flex flex-col items-center justify-center">
        <h1 className="title text-7xl pb-7 font-medium">
          🌮 Battle of the Bites! 🍪
        </h1>
        <div className="text-2xl w-[30rem] min-h-[35rem] px-8 pt-8 pb-4 bg-sky-200 rounded-lg shadow-xl flex flex-col">
          <div className="text-slate-700 text-4xl text-center">
            {view === "voting" ? "Which is better?" : "Leaderboard"}
          </div>

          <div className="grow pt-8">
            {view === "voting" && <VotingView />}
            {view === "leaderboard" && <LeaderboardView />}
          </div>

          <div className="w-full h-px bg-slate-400 my-4" />

          <div className="w-full flex justify-center truncate">
            {view === "voting" && (
              <Button primary onClick={swapViews} label="Leaderboard" />
            )}
            {view === "leaderboard" && (
              <Button primary onClick={swapViews} label="Back" />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
