import "@johnlindquist/kit"

export async function hello(name: string) {
  return `Hello ${name}!`;
}

export interface Choice {
  name: string;
  value: string;
}

export interface ArgOptions {
  placeholder: string;
  choices: Choice[];
}

export async function scriptKitArg(options: ArgOptions): Promise<string> {
  const result = await arg({
    placeholder: options.placeholder,
    choices: options.choices,
  });
  return result;
}

export async function scriptKitDiv(htmlContent: string): Promise<null> {
  await div(htmlContent);
  return null;
}

export async function scriptKitMd(markdownContent: string): Promise<string> {
  return md(markdownContent);
}
