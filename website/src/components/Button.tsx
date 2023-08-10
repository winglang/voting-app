import classnames from "classnames";
import { SpinnerLoader } from "./SpinnerLoader";

export interface ButtonProps {
  label: string;
  primary?: boolean;
  onClick: () => void;
  loading?: boolean;
  disabled?: boolean;
  className?: string;
}

export const Button = ({
  label,
  primary = false,
  onClick,
  loading = false,
  disabled = false,
  className,
}: ButtonProps) => {
  return (
    <button
      className={classnames(
        primary && "bg-sky-600 hover:bg-sky-700 text-white font-bold",
        !primary && "bg-sky-100 hover:bg-sky-300 text-slate-700",
        "py-1 px-3 rounded shadow",
        { "opacity-50 cursor-not-allowed": loading || disabled },
        className
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
