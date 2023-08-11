import { useEffect, useState } from "react";
import { Button } from "../components/Button";
import { fetchChoices } from "../services/fetchChoices";
import { submitVote } from "../services/submitVote";
import { VoteItem } from "../components/VoteItem";

export const VotingView = () => {
  const [choices, setChoices] = useState<string[]>(["", ""]);
  const [scores, setScores] = useState<number[]>([]);

  const [loading, setLoading] = useState(true);

  const [selectedWinnerIdx, setSelectedWinnerIdx] = useState<number>();
  const [loadingScores, setLoadingScores] = useState(false);

  useEffect(() => {
    fetchChoices().then((choices) => {
      setChoices(choices);
      setLoading(false);
    });
  }, []);

  const [winner, setWinner] = useState<string>();
  const selectWinner = async (winner: string) => {
    const loser = choices.find((choice) => choice !== winner)!;

    setLoadingScores(true);
    setSelectedWinnerIdx(choices.indexOf(winner));
    const { winner: winnerScore, loser: loserScore } = await submitVote(
      winner,
      loser
    );
    if (winner === choices[0]) {
      setScores([winnerScore, loserScore]);
    } else {
      setScores([loserScore, winnerScore]);
    }
    setWinner(winner);
    setLoadingScores(false);
  };

  const reset = async () => {
    setWinner(undefined);
    setLoading(true);
    setScores([]);
    const choices = await fetchChoices();
    setChoices(choices);
    setLoading(false);
  };

  return (
    <div className="choices space-y-4">
      <div className="flex gap-x-8">
        {choices.map((choice, index) => (
          <div className="w-1/2">
            <VoteItem
              key={index}
              name={choice}
              imageUrl={
                loading
                  ? ""
                  : `https://source.unsplash.com/featured/128x128/?${choice}&category=food`
              }
              onClick={() => selectWinner(choice)}
              disabled={loading || loadingScores}
              loading={loadingScores && selectedWinnerIdx === index}
              winner={winner}
              score={Math.floor(scores[index])}
            />
          </div>
        ))}
      </div>
      {winner !== null && (
        <div className="flex justify-center pt-4">
          <Button
            onClick={() => reset()}
            label="Next matchup"
            loading={loading}
            disabled={loadingScores}
          />
        </div>
      )}
    </div>
  );
};
