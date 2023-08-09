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
    <div className="App font-mono absolute inset-0">
      <div className="w-full h-full flex flex-col items-center justify-center">
        <div className="w-[30rem] min-h-[36rem] px-10 py-6 bg-sky-200 rounded-lg shadow-xl flex flex-col">
          <div className="text-slate-700 font-bold text-3xl text-center">
            {view === "voting" ? "Which is better?" : "Leaderboard"}
          </div>

          <div className="grow">
            {view === "voting" && <VotingView />}
            {view === "leaderboard" && <LeaderboardView />}
          </div>

          <div className="w-full flex justify-center">
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
