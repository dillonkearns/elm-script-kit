// ScriptKit globals (arg, div, editor, etc.) are injected at runtime.
// No import needed - they're available globally when running as a ScriptKit script.

// --- Types ---

export interface Choice {
  name: string;
  value: string;
  description?: string;
}

export interface ArgOptions {
  placeholder: string;
  choices: Choice[];
}

export interface FieldSpec {
  label: string;
  type: string;
  element: string;
  placeholder?: string;
  required: boolean;
  value?: string;
  min?: number;
  max?: number;
  step?: string;
  rows?: number;
  options?: string[];
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
  const fieldDefs = specs.map(spec => {
    const field: any = {
      label: spec.label,
    };

    if (spec.type && spec.type !== "text") field.type = spec.type;
    if (spec.placeholder) field.placeholder = spec.placeholder;
    if (spec.value) field.value = spec.value;
    if (spec.required) field.required = spec.required;

    // Handle textarea
    if (spec.element === "textarea") {
      field.type = "textarea";
      if (spec.rows) field.rows = spec.rows;
    }

    // Number constraints
    if (spec.min !== undefined) field.min = spec.min;
    if (spec.max !== undefined) field.max = spec.max;
    if (spec.step) field.step = spec.step;

    return field;
  });

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

export async function scriptKitPaste(): Promise<string> {
  return await paste();
}

export async function scriptKitTemplate(templateString: string): Promise<string> {
  return await template(templateString);
}

export async function scriptKitOpen(url: string): Promise<null> {
  await open(url);
  return null;
}

// --- Text Selection ---

export async function scriptKitGetSelectedText(): Promise<string> {
  return await getSelectedText();
}

export async function scriptKitSetSelectedText(text: string): Promise<null> {
  await setSelectedText(text);
  return null;
}

// --- Environment ---

export async function scriptKitEnv(varName: string): Promise<string> {
  return await env(varName);
}

// --- Database ---

interface DbGetOptions {
  name: string;
}

interface DbWriteOptions {
  name: string;
  data: any;
}

interface DbClearOptions {
  name: string;
}

export async function scriptKitDbGet(options: DbGetOptions): Promise<any | null> {
  console.log(`[db] Getting "${options.name}"...`);
  // Initialize with schema that includes 'value' key - ScriptKit's db proxy requires this
  const database = await db(options.name, { value: null });
  const data = database.value;

  if (data === undefined || data === null) {
    console.log(`[db] Cache MISS`);
    return null;
  }

  const itemCount = Array.isArray(data) ? data.length : 1;
  console.log(`[db] Cache HIT - ${itemCount} item(s)`);
  return data;
}

export async function scriptKitDbWrite(options: DbWriteOptions): Promise<null> {
  const itemCount = Array.isArray(options.data) ? options.data.length : 1;
  console.log(`[db] Writing "${options.name}" - ${itemCount} item(s)...`);

  // Initialize with schema that includes 'value' key
  const database = await db(options.name, { value: null });
  database.value = options.data;
  await database.write();

  console.log(`[db] Write complete`);
  return null;
}

export async function scriptKitDbClear(options: DbClearOptions): Promise<null> {
  console.log(`[db] Clearing "${options.name}"...`);

  const database = await db(options.name);
  await database.clear();

  console.log(`[db] Clear complete`);
  return null;
}

// --- Spotify ---

export async function spotifyGetAccessToken(): Promise<string> {
  console.log(`[spotify] Getting access token...`);
  const clientId = await env("SPOTIFY_CLIENT_ID");
  const clientSecret = await env("SPOTIFY_CLIENT_SECRET");

  const authString = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${authString}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    throw new Error(`Spotify auth failed: ${response.status}`);
  }

  const data = await response.json();
  return data.access_token;
}
