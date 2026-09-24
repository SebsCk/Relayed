extends Node

# Autoload (ChapterContent). Story and quest content per chapter. Only chapter 1 (Network fundamentals)
# is authored so far. Chapters listed in HUB_CHAPTERS play through the chapter
# hub (scenes/chapter_hub.tscn: main objectives, side quests, Field Notes)
# instead of going straight into their gameplay scene. Stars are never tied
# to speed — only to how much of the chapter the player explored.

const HUB_CHAPTERS := [1]

# Star rules: 1 star = all main objectives; 2 stars = also this many side
# quests; 3 stars = every side quest.
const STAR2_SIDE_QUESTS := 2

# "Lean network" side quest: bring the block online with this many towers
# or fewer (counted when the final round completes). Untuned — adjust after
# playtesting the round layouts.
const BUDGET_MAX_SITES := 4

const CHAPTERS := {
	1: {
		"title": "First Contact",
		"topic": "Network fundamentals",
		"intro": [
			{"speaker": "Mayor Santos", "text": "Welcome to Relay City, Trainee. A storm last night knocked out our connections. Nobody can call, text, or get online."},
			{"speaker": "Nurse Liza", "text": "The clinic can't reach the hospital across town. Patients are waiting. We need a link, fast!"},
			{"speaker": "Mayor Santos", "text": "You'll fix it step by step. There is no timer and no penalty for mistakes, so take your time."},
			{"speaker": "Mayor Santos", "text": "Talk to people, explore the block, and learn how networks really work. The more you discover, the more stars the city earns."},
		],
		"outro": [
			{"speaker": "Nurse Liza", "text": "The hospital just picked up. You did it, Trainee!"},
			{"speaker": "Mayor Santos", "text": "Remember: every network needs a sender, a medium to carry the message, and a receiver. And a network is many things connected together."},
		],
		"outro_by_stars": {
			1: "The block is back online. Side quests around the city can earn you more stars whenever you like.",
			2: "Great work! A few side quests are still waiting if you want that last star.",
			3: "You found every secret on this block. Relay City is lucky to have you.",
		},
		"main": [
			{"id": "first_call", "title": "First call", "desc": "The clinic must reach the hospital. Choose how to carry the message."},
			{"id": "follow_message", "title": "Follow the message", "desc": "Watch a message travel, then name the sender, the medium and the receiver."},
			{"id": "bring_online", "title": "Bring the block online", "desc": "Place towers so every building on the block is connected."},
		],
		"side": [
			{"id": "ask_around", "title": "Ask around", "desc": "Tap each building on the block and listen to its residents.", "needs_puzzle": true},
			{"id": "wired_wireless", "title": "Wired or wireless?", "desc": "Pick the best kind of link for three places in town.", "needs_puzzle": false},
			{"id": "budget", "title": "Lean network", "desc": "Bring the block online using as few towers as you can.", "needs_puzzle": true},
			{"id": "history", "title": "History corner", "desc": "Three quick questions about how phones came to be.", "needs_puzzle": false},
		],
		"notes": {
			"Building2": {
				"speaker": "Aling Rosa",
				"line": "My grandson lives across town. I just want to send him a message and know it arrives.",
				"title": "Aling Rosa",
				"text": "A message goes from a sender to a receiver.",
			},
			"Apartments2": {
				"speaker": "Kuya Migs",
				"line": "At the harbor we talk to the ferries by radio. No cables at all. The signal travels through the air!",
				"title": "Kuya Migs",
				"text": "Wireless links carry signals through the air using radio waves.",
			},
			"Apartments3": {
				"speaker": "Ate Joy",
				"line": "The whole building shares one connection. When everyone goes online at once, things slow down.",
				"title": "Ate Joy",
				"text": "Many devices can share one connection, but it can get crowded.",
			},
			"Apartments4": {
				"speaker": "Mang Tonio",
				"line": "Hilltop likes a cable link. It needs wires, but a cable is steadier than the air.",
				"title": "Mang Tonio",
				"text": "Wired links use cables. They need wires but are steady.",
			},
		},
		"terms": {
			"first_call": {"title": "Medium", "text": "The medium is what carries a message: a cable or radio waves."},
			"follow_message": {"title": "Sender and receiver", "text": "The sender starts a message. The receiver gets it."},
			"bring_online": {"title": "Network", "text": "A network is many devices and places connected so they can share messages."},
		},
		"first_call": {
			"intro": [
				{"speaker": "Nurse Liza", "text": "Trainee! The old line between the clinic and the hospital is broken. How can we get a message across?"},
			],
			"prompt": "Pick something that can carry a message between the clinic and the hospital.",
			"options": ["Just shout louder", "A cable that carries signals", "Radio waves (a wireless signal)", "Leave a sticky note on the door"],
			"correct": [1, 2],
			"wrong_feedback": "Not quite. The message needs something that can carry it across the distance.",
			"hint": "Think about what can carry a signal over a distance: wires, or the air itself.",
			"done": [
				{"speaker": "Nurse Liza", "text": "It arrived! The hospital got our message."},
				{"speaker": "Mayor Santos", "text": "Both a cable and radio waves can work. What carries the message is called the medium."},
			],
		},
		"follow_message": {
			"intro": [
				{"speaker": "Mayor Santos", "text": "Now watch a message travel from the clinic to the hospital. Then tell me who does what."},
			],
			"roles": ["Sender", "Medium", "Receiver"],
			"rows": [
				{"part": "Relay Clinic", "role": 0},
				{"part": "Radio link", "role": 1},
				{"part": "City Hospital", "role": 2},
			],
			"wrong_feedback": "Not quite. Think about who starts the message, what carries it, and who gets it.",
			"hint": "The sender starts the message, the medium carries it, and the receiver gets it.",
			"done": [
				{"speaker": "Mayor Santos", "text": "Exactly. Sender, medium, receiver. Every network you build will use these three parts."},
			],
		},
		"quiz_sets": {
			"wired_wireless": {
				"title": "Wired or wireless?",
				"done": "You matched each place to the right kind of link.",
				"questions": [
					{
						"question": "The clinic runs video calls with the hospital and cannot afford dropouts. Which link fits best?",
						"options": ["Wired (a cable)", "Wireless only", "Neither"],
						"correct": 0,
						"explanation": "A cable is usually steadier, which matters for important calls.",
						"hint": "Think about which kind of link is steadier.",
					},
					{
						"question": "The bus stop has no cables nearby and people move around all day. Which fits best?",
						"options": ["Wired (a cable)", "Wireless (radio waves)", "Neither"],
						"correct": 1,
						"explanation": "Wireless reaches people who are moving, with no cable needed.",
						"hint": "Can you run a cable to someone who is walking around?",
					},
					{
						"question": "A weekend market opens in the plaza for just two days. Which fits best?",
						"options": ["Wireless (quick to set up)", "Dig up the street for a cable", "Neither"],
						"correct": 0,
						"explanation": "Wireless is quick to set up and easy to take down.",
						"hint": "Which one is quicker to set up for only two days?",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how phones got from wires to the air.",
				"questions": [
					{
						"question": "Which came first?",
						"options": ["The landline telephone", "The smartphone", "The video call"],
						"correct": 0,
						"explanation": "Landline phones sent voices over wires long before smartphones existed.",
						"hint": "Think about the phones that had cords.",
					},
					{
						"question": "Old landline phones connected to each other using...",
						"options": ["Wires", "Bluetooth", "Satellites only"],
						"correct": 0,
						"explanation": "Early phones used copper wires strung between buildings.",
						"hint": "The word landline has the word line in it: a wire.",
					},
					{
						"question": "A mobile phone sends your call to a nearby tower using...",
						"options": ["Radio waves", "A long cable", "Sound waves through the air"],
						"correct": 0,
						"explanation": "Mobile phones use radio waves to reach towers.",
						"hint": "It is invisible and travels through the air, but it isn't sound.",
					},
				],
			},
		},
	},
}

static func uses_hub(chapter: int) -> bool:
	return HUB_CHAPTERS.has(chapter)

static func get_chapter(chapter: int) -> Dictionary:
	return CHAPTERS.get(chapter, {})

static func main_quests(chapter: int) -> Array:
	return get_chapter(chapter).get("main", [])

static func side_quests(chapter: int) -> Array:
	return get_chapter(chapter).get("side", [])

static func notes(chapter: int) -> Dictionary:
	return get_chapter(chapter).get("notes", {})

static func terms(chapter: int) -> Dictionary:
	return get_chapter(chapter).get("terms", {})

static func total_notes(chapter: int) -> int:
	return notes(chapter).size() + terms(chapter).size()

static func quest_title(chapter: int, quest_id: String) -> String:
	for quest in main_quests(chapter) + side_quests(chapter):
		if String(quest["id"]) == quest_id:
			return String(quest["title"])
	return quest_id

static func is_side_quest(chapter: int, quest_id: String) -> bool:
	for quest in side_quests(chapter):
		if String(quest["id"]) == quest_id:
			return true
	return false
