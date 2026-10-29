---
name: stitch-to-penpot
description: Workflow for copying Stitch designs to Penpot with quality validation at each step.
---

# ⚠️ CRITICAL RULES — ALWAYS FOLLOW THESE

## MANDATORY PRE-FLIGHT CHECKLIST

Before doing ANYTHING with Stitch and Penpot:

1. **ALWAYS load this skill first** using `skill(id: "stitch-to-penpot")` before starting any work
2. **ALWAYS create a NEW page in Penpot** — NEVER work on an existing page
3. **ALWAYS use PAGE IDs, never page names** — Two pages can share the same name! After creating a page, save its `page.id` and use it for ALL subsequent operations. Never use `penpotUtils.getPageByName()` — it may return the wrong page.
4. **ALWAYS use `tools.penpot.execute_code`** for all Penpot operations (this is where `penpot` and `penpotUtils` objects exist)
5. **ALWAYS use native Penbot shapes** — NEVER paste screenshots as image fills
6. **ALWAYS group elements** — NEVER leave a flat list of 100+ elements
7. **ALWAYS export and validate** each board after creating it
8. **NEVER delete or modify existing boards** — If a board already exists on the page and was NOT created by the current import process, LEAVE IT ALONE. Only touch boards you created.
9. **NEVER remove shapes you didn't create** — Use `shape.remove()` ONLY on shapes you explicitly created in the current session. Before deleting anything, verify it belongs to the current import by checking its ID against your tracked IDs.
10. **🔴 NEVER hide shapes as a workaround** — If a board is wrong, DELETE it with `shape.remove()`. Hiding with `visible=false` or moving offscreen is a CHAPUZA and creates clutter.
11. **🔴 NEVER create duplicate boards** — Plan each screen BEFORE creating it. Read the HTML, understand the structure, then create ONE board. If you need to redo it, delete the old one with `shape.remove()` first.
12. **🔴 CLEAN AS YOU GO** — After every operation, verify no stray or duplicate shapes exist. If you accidentally create extra boards, delete them immediately with `shape.remove()`.

---

## 🔴 Penpot Layout System (MANDATORY)

### Use Boards as Containers with Flex Layout
EVERY section must be a **nested board** with `addFlexLayout()`, NOT just grouped shapes.

```javascript
// Create a container board
const card = penpot.createBoard();
card.name = "Profile Card";
card.resize(440, 280);
card.borderRadius = 12;
card.fills = [{ fillColor: "#181926", fillOpacity: 1 }];
card.strokes = [{ strokeColor: "#2C2F45", strokeWidth: 1 }];
parentContainer.appendChild(card);

// Add flex layout
const flex = card.addFlexLayout();
flex.dir = "column";          // "row" | "column"
flex.wrap = "nowrap";          // "wrap" | "nowrap"
flex.rowGap = 16;
flex.columnGap = 12;
flex.alignItems = "center";    // "start" | "end" | "center" | "stretch"
flex.justifyContent = "space-between"; // "start" | "end" | "center" | "space-between" | "space-around" | "space-evenly"
flex.horizontalPadding = 24;
flex.verticalPadding = 20;

// Add children - flex auto-positions them
const child = penpot.createText("Hello");
card.appendChild(child); // No manual x/y needed!
```

### Layout Structure Template
```
Main Board (1440x1556) - flex: row
├── Sidebar Board (240px) - flex: column
│   ├── Logo
│   ├── Nav Items Board - flex: column
│   │   └── Nav Item Board - flex: row (icon + text)
│   ├── Spacer
│   ├── Button Board - flex: center
│   └── User Card Board - flex: row
├── Content Board - flex: column
│   ├── Header Board - flex: row
│   ├── Content Header Board - flex: row, space-between
│   └── Two Columns Board - flex: row
│       ├── Left Column Board - flex: column
│       │   ├── Profile Card Board - flex: column
│       │   ├── Payment Methods Board - flex: column
│       │   └── Preferences Board - flex: column
│       └── Right Column Board - flex: column
│           ├── Analytics Board - flex: column
│           ├── Distribution Board - flex: column
│           └── Timeline Board - flex: column
```

### ⚠️ CRITICAL: Every Card/Section = Board with Flex
- NEVER create loose shapes on a board
- ALWAYS create a board as container first
- THEN add flex layout to the board
- THEN append children to the board (they auto-position)

### 🔴 CHECK FOR OVERFLOW BEFORE AND AFTER
Before creating any board, verify it fits inside its parent:
```javascript
// Check if child fits in parent
if (child.x + child.width > parent.x + parent.width) {
  // OVERFLOW RIGHT - reduce width or resize parent
}
if (child.y + child.height > parent.y + parent.height) {
  // OVERFLOW BOTTOM - reduce height or resize parent
}
```
- Always verify after creating: run overflow check script
- Fix overflows IMMEDIATELY, don't leave them

## 🔴 Visual Comparison Checklist (MANDATORY after each screen)

After creating a screen, ALWAYS compare with the original Stitch design:

### Elements to verify exist:
1. **Sidebar icons** - Every nav item MUST have an icon (emoji or SVG)
2. **Charts/graphs** - Donut charts, progress rings, segmented bars MUST be recreated
3. **Payment method icons** - Use proper icons (📱💳🏦), not colored rectangles
4. **All text labels** - Including "100% AUDITADO", "Ritmo Óptimo", etc.
5. **Badge text** - Exact text from original ("Por defecto", "Instantánea", etc.)
6. **Button text** - Exact text ("Descargar Certificado" not just "Descargar")
7. **Date/time info** - "Ayer, 18:42", "14 Oct, 11:15", etc.
8. **Status indicators** - Dots, checkmarks, progress indicators

### Layout to verify:
1. **Sidebar** - Logo, nav items with icons, user card, "Nuevo Gasto" button
2. **Header** - Search bar, currency selector, notifications, action button
3. **Content header** - Breadcrumb, title, sync badge, export button
4. **Two-column layout** - Left (profile, payments, preferences) | Right (analytics, distribution, timeline)
5. **Card shadows** - Every card MUST have shadows
6. **Card strokes** - Every card MUST have borders
7. **Proper spacing** - Use flex layouts with rowGap/columnGap

### Common missing elements:
- Donut charts showing percentages
- "100% AUDITADO" labels
- "Ritmo Óptimo" with trend icon
- Icon emojis in sidebar nav
- Payment method icons (📱💳🏦)
- Exact button text from original
- Date/time stamps on timeline events

### Use Boards as Containers with Flex Layout
EVERY section must be a **nested board** with `addFlexLayout()`, NOT just grouped shapes.

```javascript
// Create a container board
const card = penpot.createBoard();
card.name = "Profile Card";
card.resize(440, 280);
card.borderRadius = 12;
card.fills = [{ fillColor: "#181926", fillOpacity: 1 }];
card.strokes = [{ strokeColor: "#2C2F45", strokeWidth: 1 }];
parentContainer.appendChild(card);

// Add flex layout
const flex = card.addFlexLayout();
flex.dir = "column";          // "row" | "column" | "row-reverse" | "column-reverse"
flex.wrap = "nowrap";          // "wrap" | "nowrap"
flex.rowGap = 16;              // spacing between items vertically
flex.columnGap = 12;           // spacing between items horizontally
flex.alignItems = "center";    // "start" | "end" | "center" | "stretch"
flex.justifyContent = "space-between"; // "start" | "end" | "center" | "stretch" | "space-between" | "space-around" | "space-evenly"
flex.horizontalPadding = 24;   // padding inside the container
flex.verticalPadding = 20;

// Add children - flex auto-positions them
const child = penpot.createText("Hello");
card.appendChild(child); // No manual x/y needed!
```

### Layout Structure Template
```
Main Board (1440x1556) - flex: row
├── Sidebar Board (240px) - flex: column
│   ├── Logo
│   ├── Nav Items Board - flex: column
│   │   └── Nav Item Board - flex: row (icon + text)
│   ├── Spacer
│   ├── Button Board - flex: center
│   └── User Card Board - flex: row
├── Content Board - flex: column
│   ├── Header Board - flex: row
│   ├── Content Header Board - flex: row, space-between
│   └── Two Columns Board - flex: row
│       ├── Left Column Board - flex: column
│       │   ├── Profile Card Board - flex: column
│       │   ├── Payment Methods Board - flex: column
│       │   └── Preferences Board - flex: column
│       └── Right Column Board - flex: column
│           ├── Analytics Board - flex: column
│           ├── Distribution Board - flex: column
│           └── Timeline Board - flex: column
```

### ⚠️ CRITICAL: Every Card/Section = Board with Flex
- NEVER create loose shapes on a board
- ALWAYS create a board as container first
- THEN add flex layout to the board
- THEN append children to the board (they auto-position)

### ❌ `penpot.pages` DOES NOT EXIST
The Penpot plugin API does NOT have a `penpot.pages` property. Do NOT try to iterate pages.

### ✅ `penpot.currentPage` PERSISTS between calls
Unlike what was previously documented, `penpot.currentPage` DOES persist between `execute_code` calls. After creating a page, `penpot.currentPage` stays on that page.

### ✅ CORRECT Page Setup (Simple & Reliable)
```javascript
// Step 1: Create page (once)
const result = await tools.penpot.execute_code({ code: `
  const page = penpot.createPage();
  page.name = "Project Name - Stitch Import";
  return JSON.stringify({ pageId: page.id });
` });
const PAGE_ID = JSON.parse(result).pageId;

// Step 2: Use penpot.currentPage directly (it persists!)
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage; // Already on the right page
  const board = penpot.createBoard();
  board.name = "My Screen";
  board.resize(1440, 900);
  page.root.appendChild(board);
  board.x = 0;
  board.y = 0;
  return JSON.stringify({ boardId: board.id });
` });
```

### ❌ `penpot.createText()` — WRONG signature
`penpot.createText()` does NOT accept no arguments. You CANNOT set `.characters` separately.

### ✅ `penpot.createText("text string")` — CORRECT
```javascript
const text = penpot.createText("Hello World");
text.fontSize = 16;
text.fontFamily = "Plus Jakarta Sans";
text.fontWeight = 600;
text.fills = [{ fillColor: "#FFFFFF", fillOpacity: 1 }];
text.x = 40;
text.y = 30;
board.appendChild(text);
```

### ❌ `penpot.removeShape()` DOES NOT EXIST
There is NO `penpot.removeShape()` function.

### ✅ `shape.remove()` — CORRECT way to delete any shape
Every shape (board, rectangle, text, ellipse, group) has a `remove()` method:
```javascript
// Delete a board
board.remove();

// Delete a rectangle
rect.remove();

// Delete multiple shapes
for (const shape of shapesToDelete) {
  shape.remove();
}
```

### ❌ NEVER hide shapes as a workaround
Hiding shapes (`shape.visible = false; shape.x = -99999`) is a CHAPUZA. Always use `shape.remove()` to properly delete.

### Example: Creating a board (CORRECT way)

```javascript
const PAGE_ID = "8f390942-4069-8006-8008-9e1ca7bbf137";

await tools.penpot.execute_code({ code: `
  // penpot.currentPage already points to the right page
  const page = penpot.currentPage;

  // Create board on the correct page
  const board = penpot.createBoard();
  board.name = "My Screen";
  board.resize(1440, 900);
  page.root.appendChild(board);
  board.x = 0;
  board.y = 0;

  return JSON.stringify({ boardId: board.id });
` });
```

### Example: Finding and appending to a board (CORRECT way)

```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  // Find the board
  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  if (!board) throw new Error("Board not found!");

  // Create and append shapes
  const rect = penpot.createRectangle();
  rect.name = "Background";
  rect.resize(1440, 900);
  rect.fills = [{ fillColor: "#0B0C10", fillOpacity: 1 }];
  board.appendChild(rect);

  return JSON.stringify({ rectId: rect.id });
` });
```

### ❌ WRONG — Trying to use penpot.pages (DOESN'T EXIST):
```javascript
await tools.penpot.execute_code({ code: `
  for (const p of penpot.pages) { // ❌ penpot.pages is undefined!
    // ...
  }
` });
```

### ✅ CORRECT — Use penpot.currentPage directly:
```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage; // ✅ Already on the right page
  const board = penpot.createBoard();
  board.name = "My Screen";
  page.root.appendChild(board);
  return JSON.stringify({ boardId: board.id });
` });
```

### Summary of Rules for Page ID:
1. **Save the page ID** immediately after creating the page
2. **Include the page ID** in every `execute_code` call as a string literal (for reference)
3. **Use `penpot.currentPage`** directly — it persists after page creation
4. **Use `page.root.appendChild(board)`** for explicit parenting
5. **NEVER use `penpot.pages`** — it doesn't exist in the API

## When Delegating to Subagents

### 🔴 CRITICAL LESSONS LEARNED (2026-09-12)

**What went wrong with subagents:**
1. Subagents were given file paths but couldn't analyze HTML properly
2. Too many screens per subagent (4-5) caused incomplete work
3. Subagents created empty boards or boards with too few elements
4. No pattern was established before delegating
5. Subagents didn't have the exact design tokens in their context

**What works:**
1. **MAX 2 screens per subagent** — quality drops with more
2. **Include the EXACT element inventory in the prompt** — don't make subagents read HTML
3. **Include the EXACT design tokens** (colors, fonts, sizes) in the prompt
4. **Include a COMPLETE EXAMPLE of one screen** — show the full `execute_code` for one board
5. **Pre-analyze the HTML yourself** — extract all text, icons, buttons, sections
6. **Verify each subagent's output** before moving to the next batch

### Subagent Delegation Template

When spawning a subagent for this work:
1. **Load this skill FIRST** in the parent conversation
2. **Pre-analyze the HTML** — extract complete element inventory (texts, icons, buttons, sections, images)
3. **Include the FULL element inventory** in the subagent prompt (not file paths)
4. **Include ALL design tokens** (exact hex colors, font sizes, spacing)
5. **Include a complete working example** of one screen's `execute_code`
6. **Limit to 2 screens per subagent** for quality
7. **Pass the PAGE_ID** explicitly
8. **Verify output** — check shape count, export and compare

---

## What I do
- Manage the workflow: Stitch (design generation) → Penpot (implementation)
- Ensure quality at each transition
- Validate designs before and after transfer

---

## Board Size Standards (ALWAYS use these)

| Device | Width | Height (typical) | Notes |
|--------|-------|-------------------|-------|
| **Desktop** | **1440px** | 900–2766px (content-driven) | Main working size |
| **Tablet** | **768px** | 1024px+ (content-driven) | iPad portrait |
| **Mobile** | **390px** | 844px+ (content-driven) | iPhone standard |

- Width is FIXED per device, height adapts to content
- When importing Stitch screens at different sizes, RESIZE boards to match these standards
- Maintain consistent spacing: 16px mobile, 24px tablet, 32px desktop
- Keep consistent corner radius across devices: 8px (small), 12px (medium), 16px (large)

---

## Board Layout on Canvas

- **Same design line** (e.g., all dark screens): place boards horizontally in a ROW, spaced 200px apart
- **Different design lines** (e.g., dark vs light): place each line in a NEW ROW below the previous one
- **Row organization:**
  ```
  Row 1 (y=0):       [Dark Desktop boards...]
  Row 2 (y=2200):    [Light Desktop boards...]
  Row 3 (y=4400):    [Mobile boards...]
  ```
- **Design Tokens board**: always at the START of Row 1 (x=0, y=0)
- Spacing between rows: 400px minimum to avoid visual overlap
- Spacing between boards in same row: 200px

---

## 🔴 Component-Based Workflow (RECOMMENDED)

### Why Components?
Creating components on a separate page ensures:
1. **Reusability** - Same component used across multiple screens
2. **Consistency** - Change once, update everywhere
3. **Clean views** - Views page only contains layouts, not raw shapes
4. **Easier maintenance** - Components and views are separated

### Step 0a: Create Components Page
```javascript
const result = await tools.penpot.execute_code({ code: `
  // Create components page
  const compPage = penpot.createPage();
  compPage.name = "Components";
  
  // Create views page
  const viewsPage = penpot.createPage();
  viewsPage.name = "Views";
  
  return JSON.stringify({ 
    compPageId: compPage.id, 
    viewsPageId: viewsPage.id 
  });
` });
```

### Step 0b: Create Reusable Components
On the Components page, create boards for each component:
```
Components Page:
├── Sidebar
│   ├── Nav Item (with icon + text)
│   ├── User Card
│   └── Nuevo Gasto Button
├── Header
│   ├── Search Bar
│   ├── Currency Selector
│   └── Saldar Button
├── Cards
│   ├── Profile Card
│   ├── Payment Method Row
│   ├── Toggle Row
│   ├── Analytics Card
│   ├── Category Card
│   └── Timeline Event
└── Badges
    ├── Verified Badge
    ├── Sync Badge
    └── Status Badge
```

### Step 0c: Use Components in Views
On the Views page, reference components by their board IDs and create layouts.

---

## 🔴 CRITICAL LESSONS LEARNED (2026-09-12)

### ❌ What went wrong (NEVER repeat these):

1. **Pixel-by-pixel recreation without understanding layout structure**
   - WRONG: Positioning every element manually with x/y coordinates
   - RIGHT: Study the HTML layout system first (grid, flex, columns), then recreate the structure

2. **Ignoring the original design's layout system**
   - WRONG: Using fixed x/y positions for everything
   - RIGHT: If original uses `grid-cols-12`, use Penpot's grid/flex to match

3. **Creating boards taller than the viewport**
   - WRONG: Board 1440x1240 when original is 1440x900
   - RIGHT: Match the original viewport size. Content that overflows should scroll

4. **Sidebar should be fixed height (viewport height)**
   - WRONG: Sidebar grows with content (1240px)
   - RIGHT: Sidebar = viewport height (900px), content scrolls independently

5. **Flex layout not working as expected**
   - WRONG: Using flex and expecting children to auto-position correctly
   - RIGHT: Test flex behavior first. If children overflow, the parent needs to be taller OR children need `horizontalSizing: "fill"`

6. **Not reviewing visually after each step**
   - WRONG: Only checking numbers (overflow counts)
   - RIGHT: Export and COMPARE with original after EVERY major change

7. **Making changes without understanding the root cause**
   - WRONG: "Fixing" overflows by making containers taller
   - RIGHT: Understand WHY elements overflow and fix the root cause

8. **Creating content that doesn't match the original**
   - WRONG: "Something similar" to the original
   - RIGHT: EXACT match - same text, same colors, same positions, same structure

### ✅ Correct approach:

1. **STUDY THE HTML FIRST** - Read the complete HTML, understand the grid/flex structure
2. **MAP THE LAYOUT** - Identify: sidebar width, header height, column spans, gaps
3. **CREATE WITH CORRECT SIZES** - Board size = original viewport size
4. **USE FLEX/GRID** - Match the original's layout system
5. **REVIEW AFTER EVERY STEP** - Export and compare with original
6. **FIX ROOT CAUSES** - Don't patch symptoms

### ✅ Layout structure mapping (MANDATORY before creating):

```javascript
// From HTML analysis, extract:
const layoutMap = {
  viewport: { width: 2560, height: 2766 }, // Original size
  sidebar: { width: 240, position: "fixed-left" },
  header: { height: 64, position: "fixed-top" },
  content: { 
    grid: "grid-cols-12",
    leftCol: { span: 5 },  // Profile, Payments, Preferences
    rightCol: { span: 7 }  // Analytics, Timeline
  },
  gaps: { horizontal: 32, vertical: 24 }
};
```

### ✅ Board size rules:
- Desktop: 1440x900 (standard viewport)
- Sidebar: 240x900 (fixed to viewport height)
- Content area: 1200x900 (scrollable if needed)
- NEVER make boards taller than viewport unless original is taller

---

## Step-by-Step Workflow

### Step 0: Setup (BEFORE anything else)

```javascript
// ALWAYS start by creating a NEW page and SAVE ITS ID
const result = await tools.penpot.execute_code({ code: `
  const page = penpot.createPage();
  page.name = "Project Name - Stitch Import";
  return JSON.stringify({ pageId: page.id });
` });
const PAGE_ID = JSON.parse(result).pageId;
console.log("✅ PAGE CREATED WITH ID:", PAGE_ID);
// ⚠️ penpot.currentPage now stays on this page automatically!
```

### Step 0d: STUDY THE HTML LAYOUT (MANDATORY - DO THIS FIRST!)

**⚠️ NEVER start creating shapes until you understand the layout structure!**

1. **Read the complete HTML file**
2. **Identify the layout system** (grid, flex, columns)
3. **Map the structure** before writing any code

```javascript
// Analyze HTML and extract layout map
const layoutAnalysis = {
  // From tailwind.config colors
  colors: { /* extract ALL colors */ },
  
  // From HTML structure
  layout: {
    hasSidebar: true,
    sidebarWidth: 240, // from Tailwind: w-60
    headerHeight: 64,  // from h-16
    contentGrid: "grid-cols-12", // from class
    leftColSpan: 5,    // from xl:col-span-5
    rightColSpan: 7,   // from xl:col-span-7
    gap: 32,           // from gap-space-xl
  },
  
  // From HTML elements
  sections: [
    { name: "Sidebar", children: ["Logo", "NavItems", "Spacer", "NuevoGasto", "UserCard"] },
    { name: "Header", children: ["Search", "Currency", "Notifications", "SaldarBtn"] },
    { name: "LeftColumn", children: ["ProfileCard", "PaymentMethods", "Preferences"] },
    { name: "RightColumn", children: ["Analytics", "Timeline"] },
  ]
};
```

4. **Verify your understanding** - Can you draw the layout from memory?
5. **Plan the Penpot structure** - Which boards, which flex layouts

### Step 0e: VERIFY BEFORE EDITING (MANDATORY)
Before making ANY changes to an existing board:
```javascript
// ALWAYS check what exists first
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;
  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  
  // List ALL children
  const children = [];
  penpotUtils.findShapes(s => {
    if (s.parent && s.parent.id === board.id) {
      children.push({ name: s.name, type: s.type, w: s.width, h: s.height });
    }
  }, board);
  
  // Check for overflows
  const overflows = [];
  penpotUtils.findShapes(s => {
    if (s.parent && s.parent.type === "board") {
      if (s.x + s.width > s.parent.x + s.parent.width + 5) {
        overflows.push({ name: s.name, issue: "RIGHT" });
      }
      if (s.y + s.height > s.parent.y + s.parent.height + 5) {
        overflows.push({ name: s.name, issue: "BOTTOM" });
      }
    }
  }, board);
  
  return JSON.stringify({ children: children.length, overflows });
` });
```

**⚠️ AFTER CREATING THE PAGE, `penpot.currentPage` stays on it. Use it directly:**

```javascript
// Template for ALL subsequent execute_code calls:
await tools.penpot.execute_code({ code: `
  // penpot.currentPage is already on the right page after creation
  const page = penpot.currentPage;

  // Now do your work on the correct page
  const board = penpot.createBoard();
  board.name = "My Screen";
  page.root.appendChild(board);
  // ...
  return JSON.stringify({ /* results */ });
` });
```

### Step 1: Get Stitch Screen Data

1. For each screen, get the HTML code from Stitch
2. Download the HTML using `curl -L` from the `htmlCode.downloadUrl`
3. Save HTML to `/tmp/opencode/stitch-screens/` for reference

#### Step 1a: MANDATORY HTML Analysis (DO THIS BEFORE CREATING ANY BOARD)

**⚠️ You MUST read the ENTIRE HTML file and extract a complete element inventory BEFORE creating the board.**

Read the full HTML and extract:

```javascript
// PARSE THE HTML FILE AND CREATE A COMPLETE ELEMENT INVENTORY
// This MUST be done BEFORE creating any Penpot shapes

const elementInventory = {
  // 1. ALL visible text content (exact strings from the HTML)
  //    Search for: >TEXT< patterns, characters="...", innerHTML text
  texts: [
    // Include EVERY piece of visible text, no matter how small
    // Example: "MI CUENTA", "CONFIGURACIÓN & ANÁLISIS", button labels, badge text
  ],
  
  // 2. ALL Material Symbol icons (search for "material-symbols-outlined")
  //    Each icon has a name like: <span class="material-symbols-outlined">icon_name</span>
  icons: [
    // Example: "file_download", "bolt", "verified", "qr_code_2"
    // Include the icon name AND its context (which section/button it belongs to)
  ],
  
  // 3. ALL interactive elements (buttons, inputs, toggles, links)
  buttons: [
    // For each button: { text: "...", icon: "...", variant: "primary|secondary|ghost" }
  ],
  
  // 4. ALL visual sections (cards, panels, modals)
  sections: [
    // For each section: { title: "...", childCount: N }
  ],
  
  // 5. ALL images (img tags with src)
  images: [
    // For each image: { src: "...", alt: "..." }
  ],
  
  // 6. Layout structure (sidebar width, content area, header height)
  layout: {
    hasSidebar: true/false,
    sidebarWidth: 260,
    headerHeight: 64,
    // etc.
  }
};
```

**How to parse the HTML:**
1. Read the HTML file with `read()` tool
2. Search for patterns:
   - `>` followed by text and `<` — for text content
   - `material-symbols-outlined` — for icons
   - `<button` — for buttons
   - `<img` — for images
   - `class="...bg-[#` — for background colors
   - `rounded-xl`, `rounded-2xl` — for border radius
   - `shadow-[` — for shadows
3. Create the complete inventory
4. **This inventory becomes your CHECKLIST** — every item must be recreated in Penpot

#### Step 1b: Identify Design Tokens from HTML

Extract the exact color palette from the Tailwind config in the HTML:

```javascript
// The HTML contains a tailwind.config with all colors
// Search for: tailwind.config = { ... "colors": { ... } }
// Extract ALL color values

const designTokens = {
  dark: {
    background: "#0B0C10",
    surface: "#0B0C10",
    surfaceContainer: "#181926",
    // ... extract ALL colors from the dark theme
  },
  light: {
    background: "#FAF8FF",
    surface: "#FAF8FF",
    surfaceContainer: "#EAEDFF",
    // ... extract ALL colors from the light theme
  },
  fonts: {
    family: "Plus Jakarta Sans",
    weights: [400, 500, 600, 700, 800]
  }
};
```

**⚠️ Use these EXACT hex values when creating Penpot shapes — do NOT approximate or guess colors!**

### Step 2: Create Boards in Penpot

For EACH screen, use `penpot.currentPage` directly (it persists after page creation):

```javascript
// Create a board for the screen
const result = await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  // Create board on the correct page
  const board = penpot.createBoard();
  board.name = "Screen Name";
  board.resize(1440, 900); // Desktop standard width
  page.root.appendChild(board);
  board.x = 0; // Position in row
  board.y = 0; // Row position

  return JSON.stringify({ boardId: board.id });
` });
```

### Step 3: Recreate Design Elements — VISUAL FIDELITY IS MANDATORY

**⚠️ CRITICAL: You MUST recreate ALL elements — not just the main ones.**
**⚠️ CRITICAL: You MUST use shadows, strokes, opacity, border radius, and flex layouts — not just flat rectangles.**

**🔴 RULE: If the HTML has 15 text elements, your Penpot board MUST have 15 text elements.**
**🔴 RULE: If the HTML has 10 icons, your Penpot board MUST have 10 icons.**
**🔴 RULE: If the HTML has 5 badges, your Penpot board MUST have 5 badges.**
**🔴 RULE: If the HTML has subtitles, descriptions, and secondary labels — ALL of them must exist.**
**🔴 RULE: Every card MUST have shadows and strokes — NEVER create flat rectangles.**
**🔴 RULE: Every button MUST have shadows — NEVER create flat rectangles.**
**🔴 RULE: Use flex layout for rows and columns — NEVER position elements manually when flex is available.**

**Common elements that get SUPPRESSED (DO NOT SKIP THESE):**
- ✅ Subtitles and secondary text (e.g., "Última sincronización bancaria y deudas cruzadas: hoy a las 10:42")
- ✅ Badges and chips (e.g., "A tu favor", "Finanzas al día", "Debes", "Te deben")
- ✅ Icons (Material Symbols like arrow_upward, call_received, call_made, shopping_cart) — DOWNLOAD SVGs
- ✅ Progress bars and percentage indicators
- ✅ Filter pills (e.g., "Todos", "Te deben", "Debes")
- ✅ Contact avatars and counters ("+2", "+4", "+3") — DOWNLOAD REAL IMAGES
- ✅ Action buttons (e.g., "Desglose", "Optimizar transferencias", "Verificar")
- ✅ Footer text (e.g., "Sincronizado con banca abierta PSD2")
- ✅ Graph topology elements (visual connections between users)
- ✅ Total amounts (e.g., "Total: 85,60 €")
- ✅ Date/time information (e.g., "Ayer 19:30", "24 Oct")

**NEVER use screenshots as fills.** Recreate everything natively:

```javascript
// Example: Create a sidebar
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  // Find the board
  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  
  // Background rectangle
  const sidebar = penpot.createRectangle();
  sidebar.name = "Sidebar";
  sidebar.resize(260, board.height);
  sidebar.fills = [{ fillColor: "#1A1D2E", fillOpacity: 1 }];
  board.appendChild(sidebar);
  
  // Navigation items
  const navItem = penpot.createRectangle();
  navItem.name = "Nav Item - Active";
  navItem.resize(228, 44);
  navItem.borderRadius = 8;
  navItem.fills = [{ fillColor: "#2A2D3E", fillOpacity: 1 }];
  sidebar.appendChild(navItem);
  
  // Text — CORRECT: pass string to createText()
  const navText = penpot.createText("Dashboard");
  navText.name = "Nav Text";
  navText.fontSize = 14;
  navText.fontFamily = "Plus Jakarta Sans";
  navText.fills = [{ fillColor: "#FFFFFF", fillOpacity: 1 }];
  sidebar.appendChild(navText);
  
  return JSON.stringify({ sidebarId: sidebar.id });
` });
```

**⚠️ ELEMENT COUNT EXPECTATIONS:**
A typical desktop app screen should have **50-150+ shapes** minimum:
- **Backgrounds**: 3-5 rectangles (main bg, sidebar bg, header bg)
- **Cards**: 5-10 rectangles with rounded corners and fills
- **Texts**: 20-50+ text elements (titles, labels, values, subtitles, descriptions)
- **Icons**: 5-15+ icon shapes (Material Symbols or simple shapes)
- **Buttons**: 3-8 button rectangles with text
- **Badges/Chips**: 3-8 small rectangles with text
- **Avatars**: 3-10 circles or rounded rectangles
- **Dividers/Lines**: 2-5 thin rectangles

**If your board has fewer than 30 shapes for a desktop screen, you are MISSING elements.**

### Step 4: Group Elements (MANDATORY)

After creating all elements for a board, group them logically:

```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  // Find the board and group elements
  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  
  // Find related shapes by name pattern
  const sidebarShapes = penpotUtils.findShapes(
    s => s.name.startsWith("Sidebar") || s.name.startsWith("Nav"),
    board
  );
  
  // Group them
  const sidebarGroup = penpot.group(sidebarShapes);
  sidebarGroup.name = "Sidebar";
  
  return JSON.stringify({ groupId: sidebarGroup.id });
` });
```

**Suggested group structure for app screens:**
```
Board (e.g., "01 - Profile Dark")
├── Sidebar
├── Header
├── Content
│   ├── Profile Card
│   ├── Payment Methods
│   └── Preferences
└── Analytics
    ├── Metrics Cards
    ├── Category Distribution
    └── Timeline
```

**A flat list of 100+ elements is UNACCEPTABLE — always organize into groups.**

### Step 5: Extract Color Palette

After creating ALL boards for a design line, extract colors from the page:

```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  // Extract colors from the page
  const allColors = new Set();
  
  penpotUtils.findShapes(s => {
    s.fills?.forEach(f => { 
      if (f.fillColor) allColors.add(f.fillColor.toUpperCase()); 
    });
    s.strokes?.forEach(st => { 
      if (st.strokeColor) allColors.add(st.strokeColor.toUpperCase()); 
    });
  }, page.root);
  
  return JSON.stringify({ colors: [...allColors] });
` });
```

**Purpose:**
- Detect accidental color variations (e.g., `#1E2030` vs `#1E2031`)
- Find inconsistent usage
- Validate against the original Stitch design system
- Ensure no rogue colors crept in

### Step 6: MANDATORY Validation — Element Completeness Check (AFTER each board)

**⚠️ THIS STEP IS NON-NEGOTIABLE. You CANNOT skip it or rush through it.**

After creating ALL elements for a board, you MUST run a systematic validation that compares the HTML source against the Penpot board. This catches missing elements, missing icons, text overflow, and suppressed content.

#### Step 6a: Extract Element Inventory from HTML

Before creating the board, parse the HTML and create a checklist of EVERY element:

```javascript
// Run this analysis on the HTML file BEFORE creating the board
// Parse the HTML and list:
// 1. All text elements (exact text content)
// 2. All icon elements (Material Symbol names)
// 3. All buttons (text + icon)
// 4. All cards/sections (title + content)
// 5. All images (src URLs)
// 6. All interactive elements (toggles, inputs, etc.)

// Example checklist format:
const elementChecklist = {
  texts: [
    "MI CUENTA",
    "CONFIGURACIÓN & ANÁLISIS",
    "Perfil y Análisis Financiero",
    "Sincronización en vivo",
    "Exportar Reporte Fiscal",
    // ... ALL text from the HTML
  ],
  icons: [
    "file_download",
    "bolt",
    "verified",
    "qr_code_2",
    "content_copy",
    // ... ALL Material Symbol icon names
  ],
  buttons: [
    { text: "Exportar Reporte Fiscal", icon: "file_download" },
    { text: "Ver mi QR de cobro", icon: "qr_code_2" },
    // ... ALL buttons
  ],
  sections: [
    "Primary Profile Card",
    "Payment Methods Section",
    "Automation & Global Preferences",
    // ... ALL major sections
  ],
  images: [
    // ALL img src URLs
  ]
};
```

#### Step 6b: Verify Every Element Exists in Penpot

After creating the board, run this verification script:

```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  if (!board) throw new Error("Board not found!");

  // Collect ALL text content in the board
  const penpotTexts = [];
  const penpotIcons = [];
  const penpotAllShapes = [];

  penpotUtils.findShapes(s => {
    penpotAllShapes.push({
      id: s.id,
      name: s.name,
      type: s.type,
      x: s.x,
      y: s.y,
      width: s.width,
      height: s.height
    });
    if (s.type === "text") {
      penpotTexts.push(s.characters);
    }
    // Check for icon-like shapes (named after Material Symbols)
    if (s.name && (
      s.name.startsWith("icon-") || 
      s.name.startsWith("Icon") ||
      s.name.includes("material") ||
      s.type === "svg" // SVG shapes used for icons
    )) {
      penpotIcons.push(s.name);
    }
  }, board);

  // 3. Compare against checklist
  const missingTexts = [];
  const checklistTexts = [/* PASTE TEXTS FROM HTML CHECKLIST HERE */];
  
  for (const text of checklistTexts) {
    const found = penpotTexts.some(pt => 
      pt && pt.includes(text) // partial match is OK
    );
    if (!found) missingTexts.push(text);
  }

  return JSON.stringify({
    totalShapes: penpotAllShapes.length,
    textsFound: penpotTexts.length,
    iconsFound: penpotIcons.length,
    missingTexts: missingTexts,
    allShapeNames: penpotAllShapes.map(s => s.name).filter(n => n)
  }, null, 2);
` });
```

**If `missingTexts` is NOT empty → you MUST add the missing text elements before proceeding!**

#### Step 6c: Text Fitting Validation

Check that all text elements fit within their parent containers:

```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  const textOverflowIssues = [];

  penpotUtils.findShapes(s => {
    if (s.type === "text" && s.parentId !== board.id) {
      // Find the parent container
      const parent = penpotUtils.findShapeById(s.parentId);
      if (parent && parent.type !== "board") {
        // Check if text width exceeds parent width
        const textWidth = s.width || 0;
        const parentWidth = parent.width || 0;
        const textX = s.x || 0;
        const parentX = parent.x || 0;
        const relativeX = textX - parentX;
        
        if (relativeX + textWidth > parentWidth + 5) { // 5px tolerance
          textOverflowIssues.push({
            textId: s.id,
            textContent: s.characters?.substring(0, 50),
            textWidth: textWidth,
            parentWidth: parentWidth,
            parentName: parent.name,
            overflow: (relativeX + textWidth - parentWidth).toFixed(1) + "px"
          });
        }
      }
    }
  }, board);

  if (textOverflowIssues.length > 0) {
    return JSON.stringify({
      status: "❌ TEXT OVERFLOW DETECTED",
      issues: textOverflowIssues
    }, null, 2);
  }
  return JSON.stringify({ status: "✅ All texts fit within containers" });
` });
```

**If text overflow is detected → FIX IT by:**
- Reducing `fontSize` until text fits
- Increasing parent container width
- Using `growType: "auto-height"` for multi-line text
- Adding `textResize: "auto"` to allow text to shrink

#### Step 6d: Icon & Image Verification

Ensure all icons and images from the HTML are present:

```javascript
await tools.penpot.execute_code({ code: `
  const page = penpot.currentPage;

  const board = penpotUtils.findShapeById("BOARD_ID_HERE");
  
  // Count shapes by type
  const shapeCounts = {
    rectangles: 0,
    ellipses: 0,
    texts: 0,
    svgs: 0,
    images: 0,
    groups: 0,
    total: 0
  };

  penpotUtils.findShapes(s => {
    shapeCounts.total++;
    switch(s.type) {
      case "rectangle": shapeCounts.rectangles++; break;
      case "ellipse": shapeCounts.ellipses++; break;
      case "text": shapeCounts.texts++; break;
      case "svg": shapeCounts.svgs++; break;
      case "image": shapeCounts.images++; break;
      case "group": shapeCounts.groups++; break;
    }
  }, board);

  // Check minimum expected element counts
  // A typical app screen should have at minimum:
  // - 5+ rectangles (backgrounds, cards, buttons)
  // - 3+ texts (titles, labels, values)
  // - 2+ icons (if the original has icons)
  const warnings = [];
  if (shapeCounts.texts < 3) warnings.push("Too few text elements - possible missing content");
  if (shapeCounts.rectangles < 3) warnings.push("Too few rectangles - possible missing backgrounds/cards");
  if (shapeCounts.svgs === 0 && shapeCounts.images === 0) {
    warnings.push("No SVGs or images found - icons may be missing");
  }

  return JSON.stringify({
    shapeCounts: shapeCounts,
    warnings: warnings,
    status: warnings.length === 0 ? "✅" : "⚠️ CHECK REQUIRED"
  }, null, 2);
` });
```

#### Step 6e: Export and Visual Comparison

**After ALL checks pass, THEN export:**

```javascript
const exportResult = await tools.penpot.export_shape({ 
  shapeId: "BOARD_ID_HERE", 
  format: "png" 
});
```

Then compare the exported PNG against the original Stitch screenshot. Look for:
- **Missing text** — any text visible in screenshot but not in Penpot
- **Missing icons** — any Material Symbol icon visible but not recreated
- **Missing sections** — any card, button, or section that exists in screenshot but not in Penpot
- **Wrong colors** — background, text, or accent colors that don't match
- **Wrong sizing** — elements that are too large/small compared to screenshot
- **Wrong positioning** — elements that are shifted or misaligned
- **Text overflow** — text that extends beyond its container boundaries
- **Missing borders/shadows** — visual depth elements that are absent

**If ANY discrepancy is found → FIX IT IMMEDIATELY before moving to the next screen. Do NOT proceed with errors.**

---

## Color Palette Organization

Create a "Design Tokens" board at the start of Row 1:

```
DESIGN TOKENS - [Project Name]
├── Brand (primary, secondary, accent — same for all themes)
├── Dark Theme (backgrounds, text, borders)
└── Light Theme (backgrounds, text, borders)
```

---

## Rules — ZERO TOLERANCE (READ THIS OR FAIL)

### Visual Fidelity Rules
1. **🔴 USE SHADOWS ON EVERY CARD AND BUTTON** — if the original HTML has `shadow-sm`, `shadow-md`, `shadow-lg`, `shadow-xl`, you MUST add shadows:
   ```javascript
   shape.shadows = [{ offsetX: 0, offsetY: 2, blur: 8, color: "#00000033" }]; // shadow-sm
   shape.shadows = [{ offsetX: 0, offsetY: 4, blur: 12, color: "#00000040" }]; // shadow-md
   shape.shadows = [{ offsetX: 0, offsetY: 8, blur: 24, color: "#00000050" }]; // shadow-lg
   ```
2. **🔴 USE STROKES ON BORDERS** — if HTML has `border`, `border-[#xxx]`, you MUST add strokes:
   ```javascript
   shape.strokes = [{ strokeColor: "#2c2f45", strokeWidth: 1 }];
   ```
3. **🔴 USE FLEX LAYOUT FOR SPACING** — don't position elements manually when you can use flex:
   ```javascript
   const flex = board.addFlexLayout();
   flex.dir = "row";
   flex.rowGap = 16;
   flex.columnGap = 16;
   flex.alignItems = "center";
   ```
4. **🔴 MATCH FONT WEIGHTS EXACTLY** — HTML uses `font-bold` (700), `font-semibold` (600), `font-medium` (500):
   ```javascript
   text.fontWeight = 700; // font-bold
   text.fontWeight = 600; // font-semibold
   text.fontWeight = 500; // font-medium
   ```
5. **🔴 USE OPACITY FOR TRANSPARENCY** — if HTML has `/15`, `/20`, `/30`, `/40` opacity:
   ```javascript
   shape.opacity = 0.15; // for /15
   shape.opacity = 0.2;  // for /20
   ```
6. **🔴 USE BORDER RADIUS CONSISTENTLY** — `rounded-xl` = 12px, `rounded-2xl` = 16px, `rounded-full` = 9999px:
   ```javascript
   shape.borderRadius = 12;  // rounded-xl
   shape.borderRadius = 16;  // rounded-2xl
   shape.borderRadius = 9999; // rounded-full (circles)
   ```

### Image Rules
7. **🔴 DOWNLOAD AND IMPORT AVATARS** — never use initials or placeholder circles:
   ```bash
   # Download avatar from Stitch HTML img src
   curl -L "AVATAR_URL" > /tmp/avatar.png
   ```
   Then import to Penpot:
   ```javascript
   // Import image and create image shape
   const imageData = await penpot.importImage("/tmp/avatar.png");
   const img = penpot.createImage();
   img.fillImage = imageData;
   img.resize(40, 40);
   img.borderRadius = 9999; // circular
   board.appendChild(img);
   ```
8. **🔴 DOWNLOAD AND IMPORT ICONS** — Material Symbols can be downloaded as SVG:
   ```bash
   # Download Material Symbol as SVG
   curl -L "https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsoutlined/check_circle/default/24px.svg" > /tmp/icon.svg
   ```
   Or create icons as simple shapes with correct colors (circles, squares with symbols).

### Element Completeness Rules
9. **NEVER paste screenshots as image fills** for the MAIN design — this is NOT a real import
10. **ALWAYS create a NEW page** — NEVER work on an existing page
11. **🔴 ALWAYS switch to the correct page using PAGE_ID at the start of EVERY `execute_code` call** — `penpot.currentPage` does NOT persist between calls
12. **ALWAYS use `tools.penpot.execute_code`** for Penpot operations
13. **ALWAYS group elements** — flat lists are unacceptable
14. **🔴 ALWAYS run Step 6 (Element Completeness Check) after EACH board** — export alone is NOT enough validation
15. **🔴 ALWAYS verify text fitting** — no text should overflow its container (Step 6c)
16. **🔴 ALWAYS verify icons are present** — count Material Symbols in HTML vs Penpot shapes (Step 6d)
17. **🔴 ALWAYS verify element count** — if a board has < 15 shapes, you're missing elements
18. **ALWAYS use `board.appendChild(shape)`** — shapes without explicit parent land on wrong board
19. **NEVER assume shapes auto-parent** — ALWAYS use explicit `appendChild()`
20. **After creating shapes, verify** they are children of the correct board
21. **ZERO TOLERANCE for differences** — if the original has it, Penpot must have it too
22. **Collect ALL colors** — even single-use ones — to detect palette errors
23. **Use Stitch HTML code** as the source of truth for structure and styling
24. **Screenshots are reference only** — not the final output
25. **If something doesn't look right, STOP and FIX it** — never proceed with errors
26. **🔴 NEVER skip "minor" elements** — badges, small icons, secondary labels ALL matter
27. **🔴 NEVER simplify text content** — if the HTML has a long subtitle, recreate the FULL text
28. **🔴 NEVER skip icons** — every Material Symbol icon MUST be recreated (download SVG or create shapes)
29. **🔴 NEVER skip progress bars** — if HTML has a segmented bar, recreate ALL segments with correct colors
30. **🔴 NEVER skip avatars** — download real avatar images and import them as circular images
31. **🔴 NEVER skip filter pills/toggles** — if HTML has filter options, recreate ALL of them
32. **🔴 NEVER skip action buttons** — "Desglose", "Verificar", "Optimizar" etc. MUST exist with shadows
33. **🔴 NEVER skip topology/graph elements** — visual connections between users MUST be recreated
34. **🔴 NEVER skip total amounts** — "Total: 85,60 €" etc. MUST exist
35. **🔴 NEVER skip date/time information** — "Ayer 19:30", "24 Oct" etc. MUST exist
36. **🔴 NEVER skip footer text** — "Sincronizado con banca abierta PSD2" etc. MUST exist
37. **🔴 NEVER create flat rectangles for cards** — cards MUST have shadows, strokes, and border radius
38. **🔴 NEVER use solid colors for everything** — use opacity for transparent backgrounds (e.g., `opacity: 0.15` for `/15`)
39. **🔴 NEVER position elements manually when flex layout is available** — use flex for rows and columns
40. **🔴 ALWAYS compare export with original** — if it doesn't look similar, FIX IT before proceeding

---

## 🔴 Visual Fidelity — HOW TO MAKE DESIGNS LOOK REAL (NOT WIREFRAMES)

**⚠️ CRITICAL: A Penpot design without shadows, strokes, and proper spacing looks like a WIREFRAME, not a real design. You MUST use these properties to match the original Stitch output.**

### Shadows (ALWAYS use on cards, buttons, inputs)

From the Stitch HTML, extract shadow classes and convert to Penpot:

| HTML Class | Penpot Shadow |
|------------|---------------|
| `shadow-sm` | `[{offsetX:0, offsetY:1, blur:2, color:"#00000015"}]` |
| `shadow-md` | `[{offsetX:0, offsetY:4, blur:6, color:"#00000020"}]` |
| `shadow-lg` | `[{offsetX:0, offsetY:10, blur:15, color:"#00000030"}]` |
| `shadow-xl` | `[{offsetX:0, offsetY:20, blur:25, color:"#00000040"}]` |
| `shadow-2xl` | `[{offsetX:0, offsetY:25, blur:50, color:"#00000050"}]` |
| `shadow-primary-container/30` | `[{offsetX:0, offsetY:4, blur:12, color:"#5b4dff30"}]` |
| `shadow-tertiary/30` | `[{offsetX:0, offsetY:4, blur:12, color:"#ff516a30"}]` |

**Example — Card with shadow:**
```javascript
const card = penpot.createRectangle();
card.name = "Balance Card";
card.resize(521, 146);
card.borderRadius = 12;
card.fills = [{ fillColor: "#12131b", fillOpacity: 1 }];
card.shadows = [{ offsetX: 0, offsetY: 4, blur: 12, color: "#00000040" }];
card.strokes = [{ strokeColor: "#2c2f45", strokeWidth: 1 }];
board.appendChild(card);
```

### Strokes (ALWAYS use on bordered elements)

| HTML Pattern | Penpot Stroke |
|--------------|---------------|
| `border border-[#2c2f45]` | `[{strokeColor:"#2c2f45", strokeWidth:1}]` |
| `border-2 border-primary/25` | `[{strokeColor:"#412ce7", strokeWidth:2}]` |
| `ring-2 ring-surface-container-lowest` | `[{strokeColor:"#ffffff", strokeWidth:2}]` |

### Border Radius (match exactly)

| HTML Class | Penpot Value |
|------------|--------------|
| `rounded-sm` | `borderRadius = 4` |
| `rounded` | `borderRadius = 6` |
| `rounded-lg` | `borderRadius = 8` |
| `rounded-xl` | `borderRadius = 12` |
| `rounded-2xl` | `borderRadius = 16` |
| `rounded-full` | `borderRadius = 9999` |

### Opacity (for transparent backgrounds)

| HTML Pattern | Penpot Opacity |
|--------------|----------------|
| `bg-primary/10` | `opacity = 0.1` |
| `bg-primary/15` | `opacity = 0.15` |
| `bg-secondary/20` | `opacity = 0.2` |
| `bg-tertiary/15` | `opacity = 0.15` |
| `bg-[#82f5c1]/40` | Create rect with fill `#82f5c1` and `opacity = 0.4` |

### Font Weights (match exactly)

| HTML Class | Penpot Value |
|------------|--------------|
| `font-normal` | `fontWeight = 400` |
| `font-medium` | `fontWeight = 500` |
| `font-semibold` | `fontWeight = 600` |
| `font-bold` | `fontWeight = 700` |
| `font-extrabold` | `fontWeight = 800` |

### Flex Layout (use for rows and columns)

**DON'T position elements manually when you can use flex:**
```javascript
// Create a flex container for a row of cards
const row = penpot.createBoard();
row.name = "Cards Row";
row.resize(1260, 200);
row.fills = []; // transparent
board.appendChild(row);

const flex = row.addFlexLayout();
flex.dir = "row";
flex.rowGap = 16;
flex.columnGap = 16;
flex.alignItems = "stretch";

// Add cards to the flex container
for (let i = 0; i < 3; i++) {
  const card = penpot.createRectangle();
  card.name = `Card ${i}`;
  card.borderRadius = 12;
  card.fills = [{ fillColor: "#12131b", fillOpacity: 1 }];
  card.shadows = [{ offsetX: 0, offsetY: 4, blur: 12, color: "#00000040" }];
  row.appendChild(card); // Flex auto-positions!
}
```

### Downloading and Importing Images

**Avatars (from Stitch HTML img tags):**
```bash
# 1. Find img src in HTML: src="https://lh3.googleusercontent.com/..."
# 2. Download
curl -L "https://lh3.googleusercontent.com/..." > /tmp/avatar.png

# 3. Import to Penpot and create image shape
```

```javascript
// Import image
const imageFile = await penpot.importImage("/tmp/avatar.png");
const img = penpot.createImage();
img.fillImage = imageFile;
img.resize(40, 40);
img.borderRadius = 9999; // circular
img.name = "Avatar - Carlos";
board.appendChild(img);
```

**Icons (Material Symbols as SVG):**
```bash
# Download Material Symbol SVG
curl -L "https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsoutlined/home/default/24px.svg" > /tmp/icon-home.svg
```

```javascript
// Import SVG icon
const svgFile = await penpot.importImage("/tmp/icon-home.svg");
const icon = penpot.createImage();
icon.fillImage = svgFile;
icon.resize(24, 24);
icon.name = "icon-home";
card.appendChild(icon);
```

---

## Quick Reference: Penpot API

### Creating Shapes
```javascript
const rect = penpot.createRectangle();
const text = penpot.createText();
const ellipse = penpot.createEllipse();
const board = penpot.createBoard();
```

### Positioning
```javascript
// Set position relative to parent
penpotUtils.setParentXY(shape, x, y);

// Or manually
shape.x = parent.x + relativeX;
shape.y = parent.y + relativeY;
```

### Styling
```javascript
shape.fills = [{ fillColor: "#FFFFFF", fillOpacity: 1 }];
shape.strokes = [{ strokeColor: "#000000", strokeWidth: 1 }];
shape.borderRadius = 8;
shape.shadows = [{ offsetX: 0, offsetY: 2, blur: 4, color: "#00000033" }];
```

### Text
```javascript
const text = penpot.createText();
text.characters = "Hello World";
text.fontSize = 16;
text.fontFamily = "Plus Jakarta Sans";
text.fontWeight = 600;
text.fills = [{ fillColor: "#FFFFFF", fillOpacity: 1 }];
```

### Shadows (CRITICAL for visual fidelity)
```javascript
// Card shadow
shape.shadows = [{ offsetX: 0, offsetY: 4, blur: 12, color: "#00000040" }];

// Button shadow with color
shape.shadows = [{ offsetX: 0, offsetY: 4, blur: 12, color: "#5b4dff30" }];

// Multiple shadows
shape.shadows = [
  { offsetX: 0, offsetY: 2, blur: 4, color: "#00000020" },
  { offsetX: 0, offsetY: 8, blur: 16, color: "#00000030" }
];
```

### Strokes (CRITICAL for borders)
```javascript
// Simple border
shape.strokes = [{ strokeColor: "#2c2f45", strokeWidth: 1 }];

// Thicker border
shape.strokes = [{ strokeColor: "#412ce7", strokeWidth: 2 }];

// Border with opacity (use fillColor with alpha)
shape.strokes = [{ strokeColor: "#412ce740", strokeWidth: 1 }];
```

### Images (Avatars, Icons)
```javascript
// Import image from file
const imageFile = await penpot.importImage("/path/to/image.png");

// Create image shape
const img = penpot.createImage();
img.fillImage = imageFile;
img.resize(40, 40);
img.borderRadius = 9999; // circular
img.name = "Avatar";
board.appendChild(img);

// For SVG icons
const svgFile = await penpot.importImage("/path/to/icon.svg");
const icon = penpot.createImage();
icon.fillImage = svgFile;
icon.resize(24, 24);
icon.name = "icon-home";
```

### Flex Layout
```javascript
const board = penpot.createBoard();
const flex = board.addFlexLayout();
flex.dir = "row";
flex.rowGap = 16;
flex.columnGap = 16;
flex.alignItems = "center";
flex.justifyContent = "space-between";
```

### Finding Shapes
```javascript
// By ID
const shape = penpotUtils.findShapeById("shape-id");

// By name
const shape = penpotUtils.findShape(s => s.name === "My Shape");

// All matching
const shapes = penpotUtils.findShapes(s => s.type === "rectangle", board);
```

---

## Troubleshooting

### Shape not appearing
- Check it's appended to the correct board with `board.appendChild(shape)`
- Verify the board exists: `penpotUtils.findShapeById(boardId)`
- Check z-order: background shapes first, foreground later

### Wrong colors
- Extract palette from Stitch HTML/CSS
- Use exact hex values (uppercase): `"#FFFFFF"` not `"#ffffff"`
- Check `fillColor` property, not `color`

### Elements misaligned
- Use `penpotUtils.setParentXY(shape, x, y)` for relative positioning
- Check if board has flex layout — it overrides manual positioning
- Use consistent spacing (16/24/32px based on device)

### Text not rendering
- Set `growType` to `"auto-width"` or `"auto-height"` after creation
- Verify `fontFamily` matches available fonts
- Check `fontSize` is reasonable (12-48px for most UI text)

### 🔴 Texts don't fit in their space (OVERFLOW)
This is the MOST COMMON error. Always check:
1. **Text width vs container width**: The text element's width must NOT exceed its parent container's width
2. **Relative positioning**: Calculate `text.x - parent.x + text.width` and verify it's ≤ `parent.width`
3. **Fix strategies**:
   - Reduce `fontSize` (e.g., from 16 to 14, or 14 to 12)
   - Increase parent container width
   - Use `growType: "auto-height"` for multi-line text
   - Truncate text with `...` if it's too long
   - Use shorter text content if the original allows it
4. **Validation**: Run the text fitting check (Step 6c) after EVERY board

### 🔴 Missing icons (Material Symbols)
Icons are frequently lost during recreation. Always verify:
1. **Count icons in HTML**: Search for `material-symbols-outlined` in the HTML source
2. **Count icon shapes in Penpot**: Search for shapes named "icon-*" or SVG shapes
3. **Icon recreation options**:
   - Use SVG shapes (best quality)
   - Use text elements with the Material Symbols font
   - Name them clearly: `"icon-{name}"` (e.g., `"icon-payments"`)
4. **Common missing icons**: check_circle, more_vert, arrow_upward, arrow_downward, bolt, verified, search, notifications

### 🔴 Missing elements (SUPPRESSED content)
Elements get "suppressed" (skipped) when the agent rushes. Prevention:
1. **Create a checklist** from the HTML BEFORE starting (Step 6a)
2. **Check off each element** as you create it
3. **Run the verification** (Step 6b) after the board is complete
4. **NEVER skip "minor" elements** — every button, every label, every badge matters
5. **Common suppressed elements**:
   - Small status badges (e.g., "Por defecto", "Sincronizado", "A tu favor", "Finanzas al día")
   - Secondary text labels (e.g., subtitle text under headings, descriptions like "Sube foto y divide al vuelo")
   - Divider lines and borders
   - Small icon buttons (e.g., three-dot menu `more_vert`, "Verificar", "Desglose")
   - Progress bars and percentage indicators (e.g., "69% usado", bar charts with multiple segments)
   - Avatar images and profile photos (circular or rounded)
   - Chip/badge elements (e.g., "Cuenta Verificada & Bizum Conectado", "Debes", "Te deben")
   - Filter pills and toggle buttons (e.g., "Todos", "Te deben", "Debes")
   - Graph topology elements (visual connections between users with arrows and amounts)
   - Total/summary amounts (e.g., "Total: 85,60 €", "Total: 70,00 €")
   - Date/time information (e.g., "Ayer 19:30", "24 Oct", "22 Oct")
   - "Cargar más" buttons (e.g., "Cargar más gastos antiguos (34 restantes)")
   - PSD2/banking integration text (e.g., "Sincronizado con banca abierta PSD2")
   - Tooltip/overflow text (e.g., "Optimización de transferencias cruzadas", detailed descriptions)

### 🔴 CRITICAL: Element Completeness Checklist (REAL EXAMPLE)

**This is what happened when elements were suppressed:**

| Category | Original (Stitch) | Penpot (Before Fix) | Missing |
|----------|-------------------|---------------------|---------|
| Bizum ticker | "Bizum detectado: +18,50 € de Lucía Vidal" | ❌ NO EXISTE | ENTIRE TICKER |
| Balance badge | "A tu favor" badge with arrow_upward icon | ❌ NO EXISTE | BADGE + ICON |
| Balance subtitle | "saldo ponderado" | ❌ NO EXISTE | TEXT |
| Welcome subtitle | "Última sincronización bancaria y deudas cruzadas: hoy a las 10:42" | "Última sincronización bancaria" | PARTIAL TEXT |
| Te Deben icon | call_received icon | ❌ NO EXISTE | ICON |
| Debes text | "en 2 grupos" | "de 4 amigos" | WRONG TEXT |
| Budget card | Progress bar, "Octubre 2024", "/ 700 €", "69% usado", 3 categories | "485 €" only | 95% MISSING |
| Action subtitles | "Sube foto y divide al vuelo", etc. | ❌ NO EXISTEN | 3 SUBTITLES |
| Group badges | "Debes"/"Te deben" badges | ❌ NO EXISTEN | 6 BADGES |
| Group avatars | Photos + counters "+2", "+4", "+3" | ❌ NO EXISTEN | 9 ELEMENTS |
| Group buttons | "Desglose" on each card | ❌ NO EXISTEN | 3 BUTTONS |
| Transaction filters | Pills "Todos", "Te deben", "Debes" | ❌ NO EXISTEN | 3 PILLS |
| Transaction icons | shopping_cart, restaurant, bolt, gas_station | ❌ NO EXISTEN | 4 ICONS |
| Transaction badges | "Piso Gran Vía", "Viaje a Lisboa" | ❌ NO EXISTEN | 4 BADGES |
| Transaction subtitles | "Pagaste tú • 4 personas • Ayer 19:30" | ❌ NO EXISTEN | 4 SUBTITLES |
| Transaction totals | "Total: 85,60 €" | ❌ NO EXISTEN | 4 TOTALS |
| Settlement topology | Graph "Tú → 23,50 € → Laura" | ❌ NO EXISTE | ENTIRE GRAPH |
| User avatar | Circular photo | Rectangle placeholder | WRONG TYPE |

**Total missing: ~40+ elements in a single board!**

**The fix: When you see this checklist, you MUST recreate EVERY missing element before proceeding.**

### 🔴 Element count too low
A typical app screen should have:
- **Desktop**: 30-100+ shapes (rectangles, texts, icons, groups)
- **Mobile**: 20-60+ shapes
- If your board has fewer than 15 shapes, you're almost certainly missing elements
- Run Step 6d to check shape counts and compare against the HTML
