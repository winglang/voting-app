import { Button } from "./Button";
import classnames from "classnames";
import { SpinnerLoader } from "./SpinnerLoader";
import { useMemo } from "react";

export interface VoteItemProps {
  name: string;
  image?: string;
  onClick: () => void;
  disabled?: boolean;
  loading?: boolean;
  winner?: string;
  score?: number;
}

export const VoteItem = ({
  name,
  onClick,
  image,
  disabled,
  loading,
  winner,
  score,
}: VoteItemProps) => {
  const rotateStyle = useMemo(() => {
    return {
      transform: winner && "rotateY(180deg)",
    };
  }, [winner]);

  const safeName = name.replace(/[^a-z0-9]/gi, "");
  const safeScore = score ?? 1500;
  const isWinner = winner === name ? -1 : 1;

  return (
    <div className="text-center">
      <div
        className={classnames(
          "rounded-lg bg-white",
          "transition-transform duration-300 w-full h-full transform"
        )}
        style={rotateStyle}
      >
        <h3
          className="text-3xl truncate py-2 text-slate-700 px-2 h-12"
          style={rotateStyle}
        >
          {winner && (winner === name ? "🥇" : "🥈")}
          {!winner && name}
        </h3>

        <div
          className="relative h-40 mx-auto rounded-b-lg truncate border-t-2 border-slate-500 bg-sky-100"
          style={rotateStyle}
        >
          <div className="absolute inset-0 flex items-center justify-center opacity-50">
            <SpinnerLoader />
          </div>

          {winner && (
            <div
              className={classnames(
                "w-full h-full absolute z-10 pt-5",
                winner === name ? "bg-green-100" : "bg-red-100"
              )}
            >
              <style>
                {`#${safeName}::after {
  content: counter(${safeName});
  animation: ${safeName}-anim 1.5s linear;
  counter-reset: ${safeName} ${score};
}

@keyframes ${safeName}-anim {
  0% { counter-reset: ${safeName} ${safeScore + 15 * isWinner}; }
  3% { counter-reset: ${safeName} ${safeScore + 14 * isWinner}; }
  6% { counter-reset: ${safeName} ${safeScore + 13 * isWinner}; }
  9% { counter-reset: ${safeName} ${safeScore + 12 * isWinner}; }
  12% { counter-reset: ${safeName} ${safeScore + 11 * isWinner}; }
  15% { counter-reset: ${safeName} ${safeScore + 10 * isWinner}; }
  18% { counter-reset: ${safeName} ${safeScore + 9 * isWinner}; }
  21% { counter-reset: ${safeName} ${safeScore + 8 * isWinner}; }
  24% { counter-reset: ${safeName} ${safeScore + 7 * isWinner}; }
  27% { counter-reset: ${safeName} ${safeScore + 6 * isWinner}; }
  30% { counter-reset: ${safeName} ${safeScore + 5 * isWinner}; }
  33% { counter-reset: ${safeName} ${safeScore + 4 * isWinner}; }
  36% { counter-reset: ${safeName} ${safeScore + 3 * isWinner}; }
  43% { counter-reset: ${safeName} ${safeScore + 2 * isWinner}; }
  66% { counter-reset: ${safeName} ${safeScore + 1 * isWinner}; }
  100% { counter-reset: ${safeName} ${safeScore}; }
}`}
              </style>
              Score: <span id={safeName}></span>
            </div>
          )}

          {!winner && image && (
            <img
              className="w-full h-full object-cover absolute z-10"
              src={`${image}`}
              alt={name}
            />
          )}
        </div>
      </div>

      <div className="pt-6">
        <Button
          onClick={onClick}
          label="Vote"
          loading={loading}
          disabled={disabled || winner !== undefined}
        />
      </div>
    </div>
  );
};
