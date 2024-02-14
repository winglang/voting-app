import { useState } from "react";
import { Button } from "../components/Button";
import { Choice, useFetchChoices } from "../services/fetchChoices";
import { submitVote } from "../services/submitVote";
import { VoteItem } from "../components/VoteItem";

export const VotingView = () => {
  const { choices, isLoading, fetchNewChoices } = useFetchChoices();
  const [scores, setScores] = useState<number[]>([]);

  const [loadingScores, setLoadingScores] = useState(false);

  const [winner, setWinner] = useState<string>();
  const [selectedChoice, setSelectedChoice] = useState<Choice>();

  const selectWinner = async (winner: Choice) => {
    setSelectedChoice(winner);
    const loser = choices.find((choice) => choice.label !== winner.label)!;

    setLoadingScores(true);
    const { winner: winnerScore, loser: loserScore } = await submitVote(
      winner.label,
      loser.label
    );
    if (winner === choices[0]) {
      setScores([winnerScore, loserScore]);
    } else {
      setScores([loserScore, winnerScore]);
    }
    setWinner(winner.label);
    setLoadingScores(false);
  };

  const reset = async () => {
    setWinner(undefined);
    setScores([]);
    await fetchNewChoices();
  };

  return (
    <div className="choices space-y-4">
      <div className="flex">
        {choices.map((choice, index) => (
          <div className="w-1/2 shrink-0 px-4" key={index}>
            <VoteItem
              key={index}
              name={choice.label}
              image={isLoading ? undefined : choice.imageSvg}
              onClick={() => selectWinner(choice)}
              disabled={isLoading || loadingScores}
              loading={loadingScores && selectedChoice?.label === choice.label}
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
            loading={isLoading}
            disabled={loadingScores}
          />
        </div>
      )}
    </div>
  );
};
