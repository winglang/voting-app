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

export const fetchChoices = async () => {
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
