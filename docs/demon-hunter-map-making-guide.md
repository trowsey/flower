# 🗡️ Demon Hunter's Map-Making Guide 🗡️

## Welcome, Hunter! 🌟

So you want to build your own spooky demon world? AWESOME.

You know how in Minecraft you place blocks to build things?
Making maps in Flower works kind of like that — except instead of
a pickaxe, you use the **Godot Editor**, and instead of building
a house, you're building a whole dungeon full of demons to hunt!

Let's get started. 🎵 *cue epic K-pop battle music* 🎵

---

## Chapter 1: What Even Is a Map? 🤔

A map is just a bunch of **tiles** — little square pieces — placed
next to each other to make a world. Think of it like LEGO or
Minecraft blocks, but flat (mostly).

In your demon hunting world, tiles can be:

| Tile | What It Looks Like | What It Does |
|---|---|---|
| 🟫 **Floor** | A flat stone slab | Where you walk around |
| 🧱 **Wall** | A tall block | Blocks your path (and hides demons!) |
| 🕳️ **Pit** | A dark hole in the ground | Don't fall in! (or push demons in 😈) |
| ⬆️ **Platform** | A raised-up floor | High ground — great for spotting demons |
| 🚪 **Door** | A gap in the wall | Connects one room to another |

---

## Chapter 2: Open the Map Workshop 🛠️

### Step 1: Open Godot

Double-click the Godot icon to open the engine. Your project
"Flower" should show up in the project list. Click it!

### Step 2: Find the GridMap

Look at the left side of the screen. You'll see a list of things
in your scene — it's called the **Scene Tree**. It's like a family
tree but for your game objects.

Find the node called **GridMap**. Click on it!

> 💡 **What's a GridMap?**
> It's Godot's version of Minecraft's block-placing system,
> but for making flat maps. Each cell in the grid can hold one tile.

### Step 3: Open Your Tile Palette

When you click the GridMap, a panel appears at the bottom of the
screen. It shows all your tiles — floor, wall, pit, platform, door.

This is your **palette** — like a paint palette, but instead of
colors, you pick tiles!

---

## Chapter 3: Build Your First Room 🏗️

Okay, Hunter. Time to build your first demon-hunting arena.

### Step 1: Place the Floor

1. Click the **Floor** tile in your palette (the flat stone one)
2. Now click anywhere in the big 3D view in the middle of the screen
3. CLICK CLICK CLICK to place floor tiles in a rectangle shape

> 🎮 **Pro tip:** Hold Shift and drag to paint a whole line of
> tiles at once, just like holding down the mouse in Minecraft!

Make a rectangle that's about **8 tiles wide** and **8 tiles long**.
That's your room!

```
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
  🟫🟫🟫🟫🟫🟫🟫🟫
```

### Step 2: Build the Walls

1. Click the **Wall** tile in your palette
2. Place walls all around the EDGES of your floor

```
  🧱🧱🧱🧱🧱🧱🧱🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🧱🧱🧱🧱🧱🧱🧱
```

Look at that! You made a room! 🎉

### Step 3: Add a Door

Every good demon-hunting room needs a way IN (and a way to
RUN AWAY if the demon is too scary).

1. Click the **Door** tile
2. Pick one wall tile and replace it with a door
3. Put it in the middle of one wall — that looks best

```
  🧱🧱🧱🧱🧱🧱🧱🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🧱🧱🚪🚪🧱🧱🧱
```

---

## Chapter 4: Make It Spooky 👻

A flat room is boring. Demons don't live in boring places!
Let's add some danger.

### Add a Pit of Darkness

1. Click the **Pit** tile
2. Place 2 or 3 pit tiles somewhere inside your room
3. These are dark holes — your hunter has to walk AROUND them

```
  🧱🧱🧱🧱🧱🧱🧱🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🕳️🟫🟫🟫🧱
  🧱🟫🟫🕳️🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🕳️🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🧱🧱🚪🚪🧱🧱🧱
```

### Add a Lookout Platform

1. Click the **Platform** tile
2. Place a few in a corner — this is high ground!

Your hunter can stand up here to spot demons before they attack.
It's like building a little tower in Minecraft.

```
  🧱🧱🧱🧱🧱🧱🧱🧱
  🧱🟫🟫🟫🟫⬆️⬆️🧱
  🧱🟫🟫🕳️🟫⬆️⬆️🧱
  🧱🟫🟫🕳️🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🕳️🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🧱
  🧱🧱🧱🚪🚪🧱🧱🧱
```

---

## Chapter 5: Build a Second Room 🏗️🏗️

One room isn't a dungeon — it's just a room!
Let's make a second room and connect them.

### Step 1: Build Another Room

Go past the door you made and build another floor rectangle.
This one can be a different size! Maybe **6 wide and 10 long** —
a long hallway where demons chase you!

### Step 2: Connect Them

Make sure the doors line up. Your hunter needs to be able to walk
from Room 1 through the door into Room 2.

```
  ┌─────────────────┐
  │                  │
  │    ROOM 1        │
  │   (The Arena)    │
  │                  │
  └───────🚪🚪──────┘
          │  │
    ┌─────🚪🚪──────┐
    │                │
    │    ROOM 2      │
    │ (The Hallway)  │
    │                │
    │                │
    │                │
    └────────────────┘
```

> 💡 **Big idea:** Every room you make is like a puzzle piece.
> Later, the computer can take YOUR rooms and shuffle them
> around to make a different dungeon every time you play.
> HOW COOL IS THAT?!

---

## Chapter 6: Test Your Map! 🎮

Time to see if your demon world actually works.

1. Press the **▶ Play** button at the top right of Godot
   (or press **F5**)
2. Your game starts!
3. **Click somewhere on the floor** — your hunter walks there!
4. Try walking through the door into your second room
5. Try walking near the pit — can you avoid it?

### If Something Goes Wrong 🐛

| Problem | Fix |
|---|---|
| Hunter walks through walls | Make sure wall tiles are placed, not just floor tiles that look dark |
| Hunter can't reach a room | Check that your doors line up between rooms |
| Hunter falls into the void | You're missing floor tiles! Fill in the gaps |
| Nothing happens when you click | You might be clicking on a wall — click on the floor |

---

## Chapter 7: Name Your Rooms 📝

Every great dungeon has cool room names. Here are some ideas:

- 🗡️ **The Shadow Arena** — where you fight the first demon
- 🏃 **The Corridor of Whispers** — a long creepy hallway
- 💀 **The Demon King's Throne** — the final boss room
- 🛍️ **The Hunter's Rest** — a safe room with supplies
- 🕸️ **The Web Pit** — full of pits and traps

When you build a room, think about: *What would happen here
in the story?* That helps you decide what tiles to place.

---

## Chapter 8: The Magic of Random Dungeons 🎲

Here's the REALLY cool part.

Remember how you built those rooms by hand? Well, the game
can take all your rooms and **mix them up automatically**
to make a brand new dungeon every time.

It works like this:

1. **You** build awesome rooms (The Arena, The Hallway, etc.)
2. **You** mark where the doors are on each room
3. **The computer** rolls dice 🎲 to decide the layout
4. **The computer** places your rooms in random spots
5. **The computer** builds corridors to connect them
6. **YOU** play a brand new dungeon every time!

It's like if Minecraft generated a new world using buildings
that YOU designed. Your rooms, but in a new order every time.

Same demons. Same traps. TOTALLY different dungeon. 🤯

---

## Your Quest Checklist ✅

- [ ] Build a room with floor tiles (8×8)
- [ ] Add walls around the edges
- [ ] Place a door in one wall
- [ ] Add at least one pit (spooky!)
- [ ] Add a raised platform (lookout point!)
- [ ] Build a second room
- [ ] Connect the rooms with a door
- [ ] Press Play and test it!
- [ ] Walk through both rooms
- [ ] Give your rooms cool names

---

## Bonus: Room Ideas to Try 🌟

Once you've got the basics, try making these:

### The Demon Trap Room
```
  🧱🧱🧱🧱🧱🧱🧱🧱🧱🧱
  🧱🟫🟫🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🕳️🟫🟫🟫🟫🕳️🟫🧱
  🧱🟫🟫🟫🕳️🕳️🟫🟫🟫🧱
  🧱🟫🟫🕳️🟫🟫🕳️🟫🟫🧱
  🧱🟫🕳️🟫🟫🟫🟫🕳️🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🟫🟫🧱
  🧱🧱🧱🧱🚪🚪🧱🧱🧱🧱
```
Pits everywhere! Only a skilled hunter can navigate this room.
Lure the demons in and they'll fall into the pits!

### The Boss Arena
```
  🧱🧱🧱🧱🧱🧱🧱🧱🧱🧱🧱🧱
  🧱🟫🟫🟫🟫🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫⬆️⬆️🟫🟫⬆️⬆️🟫🟫🧱
  🧱🟫🟫⬆️⬆️🟫🟫⬆️⬆️🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🟫🟫🟫🟫🧱
  🧱🟫🟫🟫🟫🟫🟫🟫🟫🟫🟫🧱
  🧱🧱🧱🧱🧱🚪🚪🧱🧱🧱🧱🧱
```
A big open room with raised platforms in the corners.
Jump up to dodge the boss's attacks! 🎵 *dramatic music* 🎵

---

## You Did It! 🎊

You just learned how to:
- Place tiles to build rooms
- Use walls, floors, pits, platforms, and doors
- Connect rooms together
- Test your map in the game

You're officially a **Demon Hunter Map Architect**! 🏆

Now go build the scariest, coolest, most epic demon dungeon ever.
The demons won't know what hit them. 💥

*— End of Guide —*
