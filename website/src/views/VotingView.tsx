import { useEffect, useState } from "react";
import { Button } from "../components/Button";
import { Choice, fetchChoices } from "../services/fetchChoices";
import { submitVote } from "../services/submitVote";
import { VoteItem } from "../components/VoteItem";

export const VotingView = () => {
  const [choices, setChoices] = useState<Choice[]>([
    { label: "" },
    { label: "" },
  ]);
  const [scores, setScores] = useState<number[]>([]);

  const [loading, setLoading] = useState(true);

  const [loadingScores, setLoadingScores] = useState(false);

  useEffect(() => {
    fetchChoices().then((choices) => {
      setChoices(choices);
      setLoading(false);
    });
  }, []);

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
    setLoading(true);
    setScores([]);
    setChoices([{ label: "" }, { label: "" }]);
    const choices = await fetchChoices();
    setChoices(choices);
    setLoading(false);
  };

  return (
    <div className="choices space-y-4">
      <div className="flex">
        {choices.map((choice, index) => (
          <div className="w-1/2 shrink-0 px-4">
            <VoteItem
              key={index}
              name={choice.label}
              image={loading ? undefined : choice.imageSvg}
              onClick={() => selectWinner(choice)}
              disabled={loading || loadingScores}
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
            loading={loading}
            disabled={loadingScores}
          />
        </div>
      )}
    </div>
  );
};
