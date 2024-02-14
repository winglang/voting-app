import { useEffect, useRef, useState } from "react";
import { fetchConfig } from "./fetchConfig";

export interface Choice {
  label: string;
  imageSvg?: string;
}

const getImageSvg = async (label: string): Promise<string> => {
  const url = `https://source.unsplash.com/featured/128x128/?${label}&category=food`;
  const response = await fetch(url);
  const blob = await response.blob();
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => {
      resolve(reader.result as string);
    };
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
};

const fetchChoices = async (): Promise<Array<Choice>> => {
  const apiUrl = (await fetchConfig()).apiUrl;
  const response = await fetch(apiUrl + "/requestChoices", {
    method: "POST",
  });
  if (!response.ok) {
    throw new Error("Failed to request choices");
  }
  const labels: string[] = await response.json();

  const choices = await Promise.all(
    labels.map(async (label) => {
      const imageSvg = await getImageSvg(label);
      return { label, imageSvg };
    })
  );
  return choices;
};

export const useFetchChoices = () => {
  const [choices, setChoices] = useState<Choice[]>([
    { label: "" },
    { label: "" },
  ]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const hasFetchedInitialChoices = useRef(false);

  const fetchNewChoices = async (userInitiated: boolean) => {
    // Prevent automatic second fetch in development mode
    if (hasFetchedInitialChoices.current && !userInitiated) {
      return;
    }

    hasFetchedInitialChoices.current = true;

    setChoices([{ label: "" }, { label: "" }]);
    setIsLoading(true);
    setError(null);
    try {
      const newChoices = await fetchChoices();
      setChoices(newChoices);
    } catch (err) {
      setError((err as any).message);
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    fetchNewChoices(false);
  }, []);

  return { choices, isLoading, error, fetchNewChoices: () => fetchNewChoices(true) };
};
