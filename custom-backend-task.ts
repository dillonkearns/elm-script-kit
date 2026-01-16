import "@johnlindquist/kit"

// --- Types ---

export interface Choice {
  name: string;
  value: string;
}

export interface ArgOptions {
  placeholder: string;
  choices: Choice[];
}

export interface FieldSpec {
  label: string;
  type: string;
}

export interface EditorOptions {
  content: string;
  language: string | null;
}

// --- User Input ---

export async function scriptKitArg(options: ArgOptions): Promise<string> {
  const result = await arg({
    placeholder: options.placeholder,
    choices: options.choices,
  });
  return result;
}

export async function scriptKitInput(placeholder: string): Promise<string> {
  return await arg(placeholder);
}

export async function scriptKitEditor(options: EditorOptions): Promise<string> {
  const editorOptions: any = {};
  if (options.language) {
    editorOptions.language = options.language;
  }
  return await editor(options.content, editorOptions);
}

export async function scriptKitFields(specs: FieldSpec[]): Promise<string[]> {
  const fieldDefs = specs.map(spec => ({
    name: spec.label,
    label: spec.label,
    type: spec.type,
  }));
  const result = await fields(fieldDefs);
  return result;
}

// --- Display ---

export async function scriptKitDiv(htmlContent: string): Promise<null> {
  await div(htmlContent);
  return null;
}

export async function scriptKitMd(markdownContent: string): Promise<string> {
  return md(markdownContent);
}

// --- File Picking ---

export async function scriptKitSelectFile(): Promise<string> {
  return await selectFile();
}

export async function scriptKitSelectFolder(): Promise<string> {
  return await selectFolder();
}

// --- Utilities ---

export async function scriptKitNotify(message: string): Promise<null> {
  await notify(message);
  return null;
}

export async function scriptKitSay(text: string): Promise<null> {
  await say(text);
  return null;
}

export async function scriptKitCopy(text: string): Promise<null> {
  await copy(text);
  return null;
}
