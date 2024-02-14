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
    // separate div to avoid being overwritten by `rotateStyle`
    <div className={classnames("transition-transform hover:scale-110")}>

      <div
        onClick={() => !disabled && winner === undefined && onClick()}
        className={classnames(
          "rounded-lg bg-white",
          "text-center transition-transform duration-300 w-full h-full transform",
          loading && "cursor-wait",
          !loading && winner === undefined &&  "cursor-pointer",
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
0% { counter-reset: ${safeName} ${safeScore + 18 * isWinner}; }
3% { counter-reset: ${safeName} ${safeScore + 17 * isWinner}; }
6% { counter-reset: ${safeName} ${safeScore + 16 * isWinner}; }
9% { counter-reset: ${safeName} ${safeScore + 15 * isWinner}; }
12% { counter-reset: ${safeName} ${safeScore + 14 * isWinner}; }
15% { counter-reset: ${safeName} ${safeScore + 13 * isWinner}; }
18% { counter-reset: ${safeName} ${safeScore + 12 * isWinner}; }
21% { counter-reset: ${safeName} ${safeScore + 11 * isWinner}; }
24% { counter-reset: ${safeName} ${safeScore + 10 * isWinner}; }
27% { counter-reset: ${safeName} ${safeScore + 9 * isWinner}; }
30% { counter-reset: ${safeName} ${safeScore + 8 * isWinner}; }
33% { counter-reset: ${safeName} ${safeScore + 7 * isWinner}; }
36% { counter-reset: ${safeName} ${safeScore + 6 * isWinner}; }
39% { counter-reset: ${safeName} ${safeScore + 5 * isWinner}; }
42% { counter-reset: ${safeName} ${safeScore + 4 * isWinner}; }
50% { counter-reset: ${safeName} ${safeScore + 3 * isWinner}; }
60% { counter-reset: ${safeName} ${safeScore + 2 * isWinner}; }
80% { counter-reset: ${safeName} ${safeScore + 1 * isWinner}; }
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
    </div>
  );
};
