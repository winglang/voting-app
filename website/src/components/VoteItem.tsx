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
          className="relative h-36 mx-auto rounded-b-lg truncate border-t-2 border-slate-500 bg-sky-100"
          style={rotateStyle}
        >
          <div className="absolute inset-0 flex items-center justify-center opacity-50">
            <SpinnerLoader />
          </div>

          {winner && (
            <div
              className={classnames(
                "w-full h-full absolute z-10",
                winner === name ? "bg-green-100" : "bg-red-100"
              )}
            >
              Score: {Math.max(score!, 0)}
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
        {!winner && (
          <Button
            onClick={onClick}
            label="Vote"
            loading={loading}
            disabled={disabled}
          />
        )}
      </div>
    </div>
  );
};
