import { Button } from "./Button";
import classnames from "classnames";

export interface VoteItemProps {
  name: string;
  imageUrl: string;
  onClick: () => void;
  disabled?: boolean;
  loading?: boolean;
  winner?: string;
  score?: number;
}

export const VoteItem = ({
  name,
  onClick,
  imageUrl,
  disabled,
  loading,
  winner,
  score,
}: VoteItemProps) => {
  return (
    <div className="text-center">
      <div className="space-y-2">
        <h3 className="text-lg truncate">{name}</h3>
        <div className="relative w-32 h-32 mx-auto">
          <div className="w-32 h-32 rounded mx-auto bg-sky-300 animate-pulse absolute shadow" />
          {imageUrl !== "" && (
            <img
              className="w-32 h-32 object-fill rounded absolute z-10"
              src={imageUrl}
              alt={name}
            />
          )}
        </div>
        {!winner && (
          <Button
            onClick={onClick}
            label="Vote"
            loading={loading}
            disabled={disabled}
          />
        )}
        {winner && (
          <div
            className={classnames(
              "h-8",
              winner === name ? "text-green-600" : "text-red-600"
            )}
          >
            {winner === name ? "🥇" : "👎"} (Score: {Math.max(score!, 0)})
          </div>
        )}
      </div>
    </div>
  );
};
