import { Button } from "./Button";
import classnames from "classnames";
import { SpinnerLoader } from "./SpinnerLoader";

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
      <h3 className="text-3xl truncate h-8 mb-5 text-slate-700">{name}</h3>
      <div className="relative w-32 h-32 mx-auto rounded-lg truncate">
        <div className="w-full h-full bg-sky-100 animate-pulse absolute shadow items-center justify-center flex opacity-50">
          <SpinnerLoader />
        </div>
        {imageUrl !== "" && (
          <img
            className="w-full h-full object-fill absolute z-10"
            src={imageUrl}
            alt={name}
          />
        )}
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
