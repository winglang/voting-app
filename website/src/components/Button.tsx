import classnames from "classnames";
import { SpinnerLoader } from "./SpinnerLoader";

export interface ButtonProps {
  label: string;
  primary?: boolean;
  onClick: () => void;
  loading?: boolean;
  disabled?: boolean;
}

export const Button = ({
  label,
  primary = false,
  onClick,
  loading = false,
  disabled = false,
}: ButtonProps) => {
  return (
    <button
      className={classnames(
        primary && "bg-sky-600 hover:bg-sky-700 text-white font-bold",
        !primary && "bg-sky-100 hover:bg-sky-300 text-slate-800",
        "py-1 px-3 rounded shadow",
        { "opacity-50 cursor-not-allowed": loading || disabled }
      )}
      onClick={onClick}
      disabled={disabled || loading}
    >
      <div className="flex gap-x-2">
        {label}
        {loading && <SpinnerLoader />}
      </div>
    </button>
  );
};
