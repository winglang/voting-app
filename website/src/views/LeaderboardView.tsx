import { useEffect, useState } from "react";
import { Entry, fetchLeaderboard } from "../services/fetchLeaderboard";
import { SpinnerLoader } from "../components/SpinnerLoader";

export const LeaderboardView = () => {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLeaderboard().then((items) => {
      setEntries(items);
      setLoading(false);
    });
  }, []);

  return (
    <div className="max-h-[23rem] overflow-y-auto">
      <table className="divide-y divide-slate-300 min-w-[20rem]">
        <thead>
          <tr>
            <th
              scope="col"
              className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-slate-900 sm:pl-0 w-full"
            >
              Name
            </th>
            <th
              scope="col"
              className="px-3 py-3.5 text-right text-sm font-semibold text-slate-900 w-32"
            >
              Score
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-300">
          {loading && (
            <tr>
              <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-slate-900 sm:pl-0 text-center w-full">
                <SpinnerLoader />
              </td>
              <td className="whitespace-nowrap px-3 py-4 text-sm text-slate-500 text-right w-32">
                <SpinnerLoader />
              </td>
            </tr>
          )}

          {entries
            .sort((a, b) => b.score - a.score)
            .map((item, index) => (
              <tr key={item.name}>
                <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-slate-900 sm:pl-0">
                  {item.name}
                </td>
                <td className="whitespace-nowrap px-3 py-4 text-sm text-slate-500 ">
                  <div className="flex justify-end gap-x-2 leading-7">
                    <div className="text-xl">
                      {index === 0 && "🥇"}
                      {index === 1 && "🥈"}
                      {index === 2 && "🥉"}
                    </div>
                    <div>{Math.max(item.score, 0)}</div>
                  </div>
                </td>
              </tr>
            ))}
        </tbody>
      </table>
    </div>
  );
};
