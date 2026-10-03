extends Node

# Autoload (ChapterContent). Story and quest content per chapter. Chapters 1 (Network
# fundamentals) and 2 (Network devices) are authored. Chapters in HUB_CHAPTERS play through the chapter
# hub (scenes/chapter_hub.tscn: main objectives, side quests, Field Notes)
# instead of going straight into their gameplay scene. Stars are never tied
# to speed — only to how much of the chapter the player explored.

const HUB_CHAPTERS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Optional per-chapter keys read by the hub / puzzle / activities:
#   "summary"       two bullet lines for the story_event objectives card
#   "outro_speaker" who delivers the star-based closing line
#   "scenario"      {"linked_after": quest_id, "online_after": quest_id}; omit to hide the clinic/hospital view
#   "puzzle"        {"main_quest": id, "budget_quest": id, "notes_quest": id} for chapters using scenes/relayed.tscn
# Quest keys: "unlock_after" (quest id that must be done first), "needs_puzzle"
# (side quests that launch the puzzle), "show_budget" / "show_notes_progress"
# (extra text on the side quest card). Quiz sets may give a question a "note"
# key (a "notes" entry earned on a correct answer) and a set an "intro".

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
		"summary": [
			"• Main: reconnect the clinic, follow a message, bring the block online",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"scenario": {"linked_after": "first_call", "online_after": "bring_online"},
		"puzzle": {"main_quest": "bring_online", "budget_quest": "budget", "notes_quest": "ask_around"},
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
			{"id": "bring_online", "title": "Bring the block online", "desc": "Place towers so every building on the block is connected.", "kind": "puzzle"},
		],
		"side": [
			{"id": "ask_around", "title": "Ask around", "desc": "Tap each building on the block and listen to its residents.", "needs_puzzle": true, "unlock_after": "follow_message", "show_notes_progress": true},
			{"id": "wired_wireless", "title": "Wired or wireless?", "desc": "Pick the best kind of link for three places in town.", "needs_puzzle": false},
			{"id": "budget", "title": "Lean network", "desc": "Bring the block online using as few towers as you can.", "needs_puzzle": true, "unlock_after": "follow_message", "show_budget": true},
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
	2: {
		"title": "The Right Device",
		"topic": "Network devices",
		"summary": [
			"• Main: meet the devices, match them to city problems, wire the block",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"intro": [
			{"speaker": "Mayor Santos", "text": "Good news, Trainee: the clinic and the hospital are talking again. Now the whole city wants to be connected."},
			{"speaker": "Aling Rosa", "text": "My grandson's message still hasn't reached my apartment. Something is missing between our building and the tower."},
			{"speaker": "Mang Tonio", "text": "That's where I come in. The storm scattered every device in the city. My shop has the parts, but you need to know which is which."},
			{"speaker": "Mayor Santos", "text": "Learn what each device does first. The right device in the right place fixes most problems."},
		],
		"outro": [
			{"speaker": "Aling Rosa", "text": "It arrived! My grandson says hello. Thank you, Trainee."},
			{"speaker": "Mang Tonio", "text": "The modem brings the internet in, the router shares it, the switch and access point spread it, and the repeater stretches it. You know them all now."},
			{"speaker": "Mayor Santos", "text": "One thing bothers me, though. That message took a strange route across the city. Next, let's find out how data chooses its path."},
		],
		"outro_by_stars": {
			1: "The devices are sorted. Side quests can earn you more stars whenever you like.",
			2: "Nicely done! A couple of side quests are still waiting for that last star.",
			3: "You know every device and every story in the shop. Relay City is lucky to have you.",
		},
		"main": [
			{"id": "meet_devices", "title": "Meet the devices", "desc": "Mang Tonio describes the devices in his shop. Name each one."},
			{"id": "right_job", "title": "Right device, right job", "desc": "Match each problem in the city to the device that solves it."},
			{"id": "wire_block", "title": "Wire the block", "desc": "Build the chain of devices in the right order so the internet reaches everyone."},
		],
		"side": [
			{"id": "hear_residents", "title": "Hear the residents", "desc": "Four neighbors describe a problem. Help each one and collect their story.", "needs_puzzle": false, "unlock_after": "meet_devices"},
			{"id": "read_lights", "title": "Read the lights", "desc": "Learn what a device's blinking lights are telling you.", "needs_puzzle": false, "unlock_after": "right_job"},
			{"id": "wrong_device", "title": "Wrong device", "desc": "Spot the device that was used for the wrong job.", "needs_puzzle": false, "unlock_after": "wire_block"},
			{"id": "history", "title": "History corner", "desc": "Three quick questions about how networks used to connect.", "needs_puzzle": false},
		],
		"notes": {
			"aling_rosa": {"speaker": "Aling Rosa", "line": "", "title": "Aling Rosa", "text": "A modem brings the internet into a building."},
			"kuya_migs": {"speaker": "Kuya Migs", "line": "", "title": "Kuya Migs", "text": "A repeater picks up a weak signal and sends it farther."},
			"ate_joy": {"speaker": "Ate Joy", "line": "", "title": "Ate Joy", "text": "A router shares one connection and directs data between devices."},
			"mang_tonio": {"speaker": "Mang Tonio", "line": "", "title": "Mang Tonio", "text": "A switch links many wired devices in one place."},
		},
		"terms": {
			"meet_devices": {"title": "Network device", "text": "A network device is equipment that connects, shares or directs data, like a modem or router."},
			"right_job": {"title": "Modem and router", "text": "A modem brings the internet in. A router shares it and directs data."},
			"wire_block": {"title": "Chain of devices", "text": "Data passes through devices in order: modem, router, then a switch or access point."},
		},
		"quiz_sets": {
			"meet_devices": {
				"title": "Meet the devices",
				"intro": [
					{"speaker": "Mang Tonio", "text": "Take a look around my shop. I'll describe a device, and you tell me its name."},
				],
				"done": "You can name the five devices in Mang Tonio's shop.",
				"questions": [
					{
						"question": "This box brings the internet into a building from outside. What is it?",
						"options": ["Switch", "Modem", "Repeater", "Access point"],
						"correct": 1,
						"explanation": "A modem connects your building to the internet provider.",
						"hint": "It is the device that talks to the outside internet.",
					},
					{
						"question": "This device shares one internet connection with many devices and decides where data goes. What is it?",
						"options": ["Modem", "Repeater", "Router", "Cable"],
						"correct": 2,
						"explanation": "A router shares the connection and directs data to the right device.",
						"hint": "It shares the connection and directs the traffic.",
					},
					{
						"question": "This device gives nearby phones and laptops a wireless connection. What is it?",
						"options": ["Access point", "Switch", "Modem", "Cable"],
						"correct": 0,
						"explanation": "An access point turns a wired connection into Wi-Fi.",
						"hint": "Think about what gives you Wi-Fi.",
					},
					{
						"question": "This device connects many wired computers in one room so they can talk to each other. What is it?",
						"options": ["Modem", "Access point", "Repeater", "Switch"],
						"correct": 3,
						"explanation": "A switch links many wired devices in one place.",
						"hint": "It has many cable ports in a row.",
					},
					{
						"question": "The signal fades far from the tower. Which device picks it up and sends it farther?",
						"options": ["Repeater", "Modem", "Switch", "Access point"],
						"correct": 0,
						"explanation": "A repeater receives a weak signal and sends it on so it reaches farther.",
						"hint": "Its name says it repeats the signal.",
					},
				],
			},
			"right_job": {
				"title": "Right device, right job",
				"intro": [
					{"speaker": "Mayor Santos", "text": "Each problem in the city needs a different device. Match them up."},
				],
				"done": "Every problem in town now has the right device.",
				"questions": [
					{
						"question": "The clinic cannot reach the internet at all. Which device do they need to bring it in?",
						"options": ["Repeater", "Modem", "Switch", "Access point"],
						"correct": 1,
						"explanation": "Only a modem connects the building to the internet provider.",
						"hint": "Which device connects to the outside internet?",
					},
					{
						"question": "The school has 30 computers but only one internet line. What shares it?",
						"options": ["Modem", "Repeater", "Router", "Access point"],
						"correct": 2,
						"explanation": "A router shares one connection among many devices.",
						"hint": "Which device shares one connection and directs data?",
					},
					{
						"question": "The plaza needs Wi-Fi for visitors' phones. What should go there?",
						"options": ["Modem", "Access point", "Switch", "Repeater"],
						"correct": 1,
						"explanation": "An access point gives nearby phones a wireless connection.",
						"hint": "Which device creates Wi-Fi?",
					},
					{
						"question": "The signal at the harbor fades near the docks. What can carry it farther?",
						"options": ["Router", "Modem", "Access point", "Repeater"],
						"correct": 3,
						"explanation": "A repeater sends a weak signal onward so it reaches farther.",
						"hint": "Which device repeats a weak signal?",
					},
				],
			},
			"wire_block": {
				"title": "Wire the block",
				"intro": [
					{"speaker": "Mang Tonio", "text": "Data passes through devices one after another. Build the chain with me, one step at a time."},
				],
				"done": "The chain works: internet, modem, router, switch, access point.",
				"questions": [
					{
						"question": "The internet arrives from outside. Which device does it reach first?",
						"options": ["Router", "Modem", "Access point", "Switch"],
						"correct": 1,
						"explanation": "The modem is the entry point from the internet provider.",
						"hint": "Which device connects to the outside internet?",
					},
					{
						"question": "After the modem, which device shares the connection and directs data?",
						"options": ["Repeater", "Modem", "Router", "Access point"],
						"correct": 2,
						"explanation": "The router shares the connection and sends data where it needs to go.",
						"hint": "It shares the connection with many devices.",
					},
					{
						"question": "The router sends data on to a switch. What does the switch do?",
						"options": ["Brings in the internet", "Connects many wired devices", "Fades the signal", "Prints messages"],
						"correct": 1,
						"explanation": "A switch links many wired devices so they can all reach the router.",
						"hint": "Think about a row of cable ports.",
					},
					{
						"question": "Last, an access point turns the connection into...",
						"options": ["A new internet line", "A phone number", "Wi-Fi for nearby phones", "Electricity"],
						"correct": 2,
						"explanation": "An access point spreads the connection wirelessly as Wi-Fi.",
						"hint": "Which device gives people Wi-Fi?",
					},
				],
			},
			"hear_residents": {
				"title": "Hear the residents",
				"done": "You helped all four neighbors and collected their stories.",
				"questions": [
					{
						"question": "Aling Rosa: \"My grandson's messages never reach our building. Which device brings the internet in?\"",
						"options": ["Repeater", "Modem", "Access point", "Switch"],
						"correct": 1,
						"explanation": "A modem brings the internet into a building.",
						"hint": "Which device connects to the outside internet?",
						"note": "aling_rosa",
					},
					{
						"question": "Kuya Migs: \"Our harbor signal gets weak near the docks. What can pass it farther?\"",
						"options": ["Repeater", "Modem", "Router", "Switch"],
						"correct": 0,
						"explanation": "A repeater picks up a weak signal and sends it farther.",
						"hint": "Which device repeats a weak signal?",
						"note": "kuya_migs",
					},
					{
						"question": "Ate Joy: \"The school has many computers on one line and it gets crowded. What shares it fairly?\"",
						"options": ["Access point", "Modem", "Repeater", "Router"],
						"correct": 3,
						"explanation": "A router shares one connection and directs data between devices.",
						"hint": "Which device shares one connection?",
						"note": "ate_joy",
					},
					{
						"question": "Mang Tonio: \"I need to link ten wired computers in my back room. What connects them?\"",
						"options": ["Switch", "Modem", "Repeater", "Access point"],
						"correct": 0,
						"explanation": "A switch links many wired devices in one place.",
						"hint": "Which device has many cable ports in a row?",
						"note": "mang_tonio",
					},
				],
			},
			"read_lights": {
				"title": "Read the lights",
				"intro": [
					{"speaker": "Mang Tonio", "text": "Devices talk to us with little lights. Learn to read them and you'll spot trouble fast."},
				],
				"done": "You can read a device's lights and tell what's wrong.",
				"questions": [
					{
						"question": "A router's power light is off. What is the most likely problem?",
						"options": ["The Wi-Fi password is wrong", "It has no power", "The internet is slow", "The cable is too long"],
						"correct": 1,
						"explanation": "If the power light is off, the device usually isn't getting power.",
						"hint": "What does a power light tell you?",
					},
					{
						"question": "The power light is on, but the internet light is off. What does that suggest?",
						"options": ["The router can't reach the internet", "The router is too hot", "Wi-Fi is working perfectly", "The screen is broken"],
						"correct": 0,
						"explanation": "The device has power, but it isn't connected to the internet.",
						"hint": "Which light is about the internet connection?",
					},
					{
						"question": "The Wi-Fi light is blinking steadily. What does that usually mean?",
						"options": ["The device is out of power", "The modem is missing", "The device is broken", "Wireless data is being sent"],
						"correct": 3,
						"explanation": "A blinking Wi-Fi light usually means data is moving over the wireless connection.",
						"hint": "Blinking often means activity.",
					},
				],
			},
			"wrong_device": {
				"title": "Wrong device",
				"intro": [
					{"speaker": "Mang Tonio", "text": "Someone mixed up the devices around town. Can you spot the mistakes?"},
				],
				"done": "You spotted every mix-up. That's a good start on troubleshooting.",
				"questions": [
					{
						"question": "An access point was plugged in where the modem should go, and the building has no internet. What went wrong?",
						"options": ["The cables are too short", "An access point can't bring in the internet, a modem does", "Access points are too slow", "Nothing is wrong"],
						"correct": 1,
						"explanation": "Only a modem connects the building to the internet provider.",
						"hint": "Which device connects to the internet provider?",
					},
					{
						"question": "A repeater was placed right beside the router. Why doesn't that help much?",
						"options": ["Repeaters only work at night", "Routers block repeaters", "A repeater helps where the signal is weak, not where it is already strong", "Repeaters need no power"],
						"correct": 2,
						"explanation": "A repeater is for extending a weak signal, so it belongs farther out.",
						"hint": "Where is the signal weak?",
					},
					{
						"question": "A switch was put where the internet should enter, but no internet arrives. Why?",
						"options": ["A switch links devices but does not connect to the internet provider", "Switches are always broken", "Switches use no cables", "It should have been a printer"],
						"correct": 0,
						"explanation": "A switch connects devices to each other, not to the internet provider.",
						"hint": "Which device is the entry point from the provider?",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how networks got from phone lines to fiber.",
				"questions": [
					{
						"question": "Old dial-up modems connected to the internet using...",
						"options": ["Satellite dishes", "A phone line", "Radio towers", "Solar panels"],
						"correct": 1,
						"explanation": "Dial-up modems used ordinary telephone lines, which is why you couldn't call and browse at once.",
						"hint": "Think about the old landline.",
					},
					{
						"question": "Before switches, many networks used hubs. A hub sends data to...",
						"options": ["Every connected device", "Only the right device", "No one", "Only routers"],
						"correct": 0,
						"explanation": "A hub repeats data to every device, while a switch sends it only where it needs to go.",
						"hint": "A hub is not picky about who gets the data.",
					},
					{
						"question": "Today, fast internet often reaches buildings through...",
						"options": ["Telegraph wires", "Fiber optic cables", "Paper mail", "Smoke signals"],
						"correct": 1,
						"explanation": "Fiber optic cables carry data as light and are very fast.",
						"hint": "Data travels as light through glass strands.",
					},
				],
			},
		},
	},
	3: {
		"title": "The Right Route",
		"topic": "Data pathways",
		"summary": [
			"• Main: trace a route, count its hops, then route the block",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"puzzle": {
			"main_quest": "route_the_block",
			"budget_quest": "budget",
			"notes_quest": "ask_around",
		},
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "Chapter 2 fixed our devices, but something's still odd. Aling Rosa's message took a strange, long way across town.",
			},
			{
				"speaker": "Delivery Dario",
				"text": "That's a routing problem, Trainee. I'm Dario, from Relay City Post. Data doesn't fly straight to its target. It hops from router to router, just like a letter passes through post offices.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Learn how paths are chosen, then help clean up the routing on this block.",
			},
		],
		"outro": [
			{
				"speaker": "Delivery Dario",
				"text": "Perfect. Messages now take the shortest, cleanest path across town.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Every hop matters. Next, let's make sure the road doesn't get too crowded. That's a job for bandwidth.",
			},
		],
		"outro_by_stars": {
			1: "The block routes cleanly now. Side quests are still open if you want more stars.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You mapped out every route in town. Well done, Trainee.",
		},
		"main": [
			{
				"id": "trace_route",
				"title": "Trace the route",
				"desc": "Follow a message as it hops from router to router and find its path.",
			},
			{
				"id": "packet_hops",
				"title": "Count the hops",
				"desc": "Learn what a hop is and why fewer hops usually means a faster path.",
			},
			{
				"id": "route_the_block",
				"title": "Route the block",
				"desc": "Connect every building with clean, non-crossing paths.",
				"kind": "puzzle",
			},
		],
		"side": [
			{
				"id": "ask_around",
				"title": "Ask around",
				"desc": "Tap each building and hear how bad routing affected them.",
				"needs_puzzle": true,
				"unlock_after": "route_the_block",
				"show_notes_progress": true,
			},
			{
				"id": "budget",
				"title": "Lean network",
				"desc": "Route the block using as few towers as you can.",
				"needs_puzzle": true,
				"unlock_after": "route_the_block",
				"show_budget": true,
			},
			{
				"id": "shortest_path",
				"title": "Shortest path",
				"desc": "Practice picking the shortest, unbroken path across town.",
				"needs_puzzle": false,
				"unlock_after": "packet_hops",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about how the internet learned to find its way.",
				"needs_puzzle": false,
			},
		],
		"notes": {
			"Building2": {
				"speaker": "Aling Rosa",
				"line": "My grandson's message finally arrived quickly. It used to wander all over town first.",
				"title": "Aling Rosa",
				"text": "A cleaner route means fewer hops and a faster trip for a message.",
			},
			"Apartments2": {
				"speaker": "Kuya Migs",
				"line": "The harbor's messages used to loop around before reaching the tower. Now they go straight.",
				"title": "Kuya Migs",
				"text": "A good route avoids unnecessary detours.",
			},
			"Apartments3": {
				"speaker": "Ate Joy",
				"line": "The school's messages used to route through a broken link. Fixing the path fixed our connection.",
				"title": "Ate Joy",
				"text": "If part of a path is broken, a message needs a different route.",
			},
			"Apartments4": {
				"speaker": "Mang Tonio",
				"line": "My shop's devices talk to the tower directly now. No more wasted hops.",
				"title": "Mang Tonio",
				"text": "Routing decides which path a message takes to reach its destination.",
			},
		},
		"terms": {
			"trace_route": {
				"title": "Router",
				"text": "A router reads a message's destination and sends it toward the next hop.",
			},
			"packet_hops": {
				"title": "Hop",
				"text": "A hop is one stop a message makes at a router on its way to its destination.",
			},
			"route_the_block": {
				"title": "Routing",
				"text": "Routing is how a network decides which path a message should take.",
			},
		},
		"quiz_sets": {
			"trace_route": {
				"title": "Trace the route",
				"intro": [
					{
						"speaker": "Delivery Dario",
						"text": "Watch a message closely. Every stop it makes is a hop, just like a letter passing through post offices.",
					},
				],
				"done": "You can trace how a message hops across the network.",
				"questions": [
					{
						"question": "A message travels from the clinic to the hospital. What do we call each stop it makes along the way?",
						"options": [
							"A hop",
							"A hotel",
							"A holiday",
							"A hobby",
						],
						"correct": 0,
						"explanation": "Each stop a message makes at a router is called a hop.",
						"hint": "Think about a message hopping from one point to the next.",
					},
					{
						"question": "Which of these best describes what a router does?",
						"options": [
							"Directs data toward its destination",
							"Stores photos",
							"Cooks food",
							"Prints paper",
						],
						"correct": 0,
						"explanation": "A router reads a message's destination and sends it toward the next hop.",
						"hint": "It's not about food or paper. Think about directions.",
					},
					{
						"question": "If a message can take a 2-hop path or a 5-hop path to the same place, which is usually faster?",
						"options": [
							"The 2-hop path",
							"The 5-hop path",
							"They are always the same",
							"Neither works",
						],
						"correct": 0,
						"explanation": "Fewer hops usually means a faster path.",
						"hint": "Which path visits fewer stops?",
					},
				],
			},
			"packet_hops": {
				"title": "Count the hops",
				"done": "You know how to count hops on a path.",
				"questions": [
					{
						"question": "What is a 'hop' in a network path?",
						"options": [
							"One stop the data makes at a router",
							"A type of dance",
							"A unit of money",
							"A kind of cable",
						],
						"correct": 0,
						"explanation": "A hop is one stop along a message's path.",
						"hint": "Think about the word itself: hopping from stop to stop.",
					},
					{
						"question": "The path from a phone to a website passes through 4 routers. How many hops is that?",
						"options": [
							"4",
							"1",
							"40",
							"0",
						],
						"correct": 0,
						"explanation": "Each router along the way counts as one hop.",
						"hint": "Count each router the data passes.",
					},
					{
						"question": "Why do network engineers try to reduce the number of hops in a path?",
						"options": [
							"To make the message travel faster",
							"To use more paper",
							"To make the tower taller",
							"To use more electricity",
						],
						"correct": 0,
						"explanation": "Fewer hops usually means less delay.",
						"hint": "Think about speed.",
					},
				],
			},
			"shortest_path": {
				"title": "Shortest path",
				"intro": [
					{
						"speaker": "Delivery Dario",
						"text": "Let's pick the shortest way across town together.",
					},
				],
				"done": "You can pick the shortest, working path across town.",
				"questions": [
					{
						"question": "Path A has 2 hops. Path B has 4 hops. Both reach the same place. Which should the message take?",
						"options": [
							"Path A",
							"Path B",
							"Either, it never matters",
							"Neither",
						],
						"correct": 0,
						"explanation": "Fewer hops usually means a faster trip.",
						"hint": "Compare the number of hops.",
					},
					{
						"question": "A path with fewer hops has a broken link partway through. Will it still work?",
						"options": [
							"No, a broken link blocks the path even if it's short",
							"Yes, always",
							"Only on weekends",
							"Only if it's raining",
						],
						"correct": 0,
						"explanation": "A broken link blocks a path no matter how short it is.",
						"hint": "Think about what a broken link does to a path.",
					},
					{
						"question": "The best path is usually the one that is...",
						"options": [
							"Short and unbroken",
							"Long and broken",
							"The longest available",
							"Chosen at random",
						],
						"correct": 0,
						"explanation": "A good path balances being short with actually working.",
						"hint": "Combine both ideas: length and whether it's broken.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how routing grew from mail routes to modern networks.",
				"questions": [
					{
						"question": "Which everyday system is the internet's hop-by-hop routing inspired by?",
						"options": [
							"The postal mail system",
							"Television broadcasting",
							"Radio waves only",
							"None of these",
						],
						"correct": 0,
						"explanation": "Like mail hopping between post offices, data hops between routers.",
						"hint": "Think about how a letter travels before it reaches you.",
					},
					{
						"question": "What do we call one of the very first networks that used this hop-by-hop routing idea?",
						"options": [
							"ARPANET",
							"Telegram",
							"Fax machine",
							"Morse code",
						],
						"correct": 0,
						"explanation": "ARPANET was an early network that pioneered hop-by-hop routing.",
						"hint": "It's the ancestor of today's internet.",
					},
					{
						"question": "True or false: routing can update automatically when a path breaks.",
						"options": [
							"True",
							"False",
						],
						"correct": 0,
						"explanation": "Modern routing can automatically reroute around broken links.",
						"hint": "Think about what happens today when a link goes down.",
					},
				],
			},
		},
	},
	4: {
		"title": "Room for Everyone",
		"topic": "Bandwidth",
		"summary": [
			"• Main: learn bandwidth, share it fairly, then balance the load",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"puzzle": {
			"main_quest": "balance_the_load",
			"budget_quest": "budget",
			"notes_quest": "ask_around",
		},
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "The paths are clean now, Trainee, but something else is choking the network. Too much traffic is squeezed into too little bandwidth.",
			},
			{
				"speaker": "Coach Bea",
				"text": "My livestream keeps freezing! I'm Bea, I run the gym upstairs.",
			},
			{
				"speaker": "Ate Joy",
				"text": "And our school's video lessons keep stuttering. We're both fighting for the same connection.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Learn about bandwidth, then help balance the load on this block.",
			},
		],
		"outro": [
			{
				"speaker": "Coach Bea",
				"text": "My stream is smooth again!",
			},
			{
				"speaker": "Ate Joy",
				"text": "And our lessons play without stuttering. Thank you, Trainee.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Well balanced. But even with enough bandwidth, some calls still feel delayed. That's lag, and it's next.",
			},
		],
		"outro_by_stars": {
			1: "The load is balanced. Side quests are still open whenever you like.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You balanced every connection on the block. Well done, Trainee.",
		},
		"main": [
			{
				"id": "what_is_bandwidth",
				"title": "What is bandwidth?",
				"desc": "Learn that bandwidth is how much data a connection can carry at once.",
			},
			{
				"id": "share_fairly",
				"title": "Share it fairly",
				"desc": "See what happens when too much traffic shares too little bandwidth.",
			},
			{
				"id": "balance_the_load",
				"title": "Balance the load",
				"desc": "Connect towers and buildings so no tower gets overloaded.",
				"kind": "puzzle",
			},
		],
		"side": [
			{
				"id": "ask_around",
				"title": "Ask around",
				"desc": "Tap each building and hear how bandwidth affected them.",
				"needs_puzzle": true,
				"unlock_after": "balance_the_load",
				"show_notes_progress": true,
			},
			{
				"id": "budget",
				"title": "Lean network",
				"desc": "Balance the load using as few towers as you can.",
				"needs_puzzle": true,
				"unlock_after": "balance_the_load",
				"show_budget": true,
			},
			{
				"id": "measure_speed",
				"title": "Measure the speed",
				"desc": "Learn how internet speed is measured and compared.",
				"needs_puzzle": false,
				"unlock_after": "what_is_bandwidth",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about how bandwidth grew over the years.",
				"needs_puzzle": false,
			},
		],
		"notes": {
			"Building2": {
				"speaker": "Aling Rosa",
				"line": "My video calls with my grandson don't freeze anymore now that the load is spread out.",
				"title": "Aling Rosa",
				"text": "Spreading demand across towers helps everyone get enough bandwidth.",
			},
			"Apartments2": {
				"speaker": "Kuya Migs",
				"line": "The harbor radio used to compete with everything else. Now it has room to breathe.",
				"title": "Kuya Migs",
				"text": "A tower that isn't overloaded can serve everyone connected to it.",
			},
			"Apartments3": {
				"speaker": "Ate Joy",
				"line": "Our classroom videos finally play smoothly during school hours.",
				"title": "Ate Joy",
				"text": "Congestion happens when too much traffic competes for one connection.",
			},
			"Apartments4": {
				"speaker": "Mang Tonio",
				"line": "My shop's devices used to slow to a crawl at lunchtime. Not anymore.",
				"title": "Mang Tonio",
				"text": "Bandwidth is like a pipe: the wider it is, the more data flows through at once.",
			},
		},
		"terms": {
			"what_is_bandwidth": {
				"title": "Bandwidth",
				"text": "Bandwidth is how much data a connection can carry at once, like the width of a pipe.",
			},
			"share_fairly": {
				"title": "Congestion",
				"text": "Congestion happens when too much traffic tries to use the same limited bandwidth.",
			},
			"balance_the_load": {
				"title": "Load balancing",
				"text": "Load balancing spreads demand across more than one tower so none of them gets overloaded.",
			},
		},
		"quiz_sets": {
			"what_is_bandwidth": {
				"title": "What is bandwidth?",
				"done": "You know what bandwidth actually means.",
				"questions": [
					{
						"question": "Bandwidth is best described as...",
						"options": [
							"How much data a connection can carry at once",
							"How fast a car can drive",
							"The color of a cable",
							"The price of internet",
						],
						"correct": 0,
						"explanation": "Bandwidth is like the width of a pipe. More bandwidth means more data can flow at once.",
						"hint": "Think about a pipe carrying water.",
					},
					{
						"question": "If a connection has more bandwidth, what usually happens?",
						"options": [
							"More data can move through it at the same time",
							"The tower gets taller",
							"The password changes",
							"Nothing changes",
						],
						"correct": 0,
						"explanation": "More bandwidth means more room for data to move at once.",
						"hint": "Picture a wider pipe.",
					},
					{
						"question": "A small pipe versus a wide pipe carrying water. Which is more like high bandwidth?",
						"options": [
							"The wide pipe",
							"The small pipe",
							"Neither",
							"Both are equal",
						],
						"correct": 0,
						"explanation": "A wide pipe carries more water at once, just like high bandwidth carries more data.",
						"hint": "Which pipe lets more water through at the same time?",
					},
				],
			},
			"share_fairly": {
				"title": "Share it fairly",
				"done": "You understand why sharing bandwidth can cause congestion.",
				"questions": [
					{
						"question": "Coach Bea and Ate Joy share one connection and both slow down. What is this called?",
						"options": [
							"Congestion",
							"Celebration",
							"Encryption",
							"Decoration",
						],
						"correct": 0,
						"explanation": "Congestion happens when too much traffic tries to use the same limited bandwidth.",
						"hint": "Think about a traffic jam.",
					},
					{
						"question": "What is one way to relieve congestion?",
						"options": [
							"Add another tower to share the load",
							"Turn off the lights",
							"Remove all buildings",
							"Paint the tower blue",
						],
						"correct": 0,
						"explanation": "Sharing demand across more towers relieves congestion.",
						"hint": "Think about spreading the traffic out.",
					},
					{
						"question": "True or false: giving each building its own coverage avoids competing for one shared tower's bandwidth.",
						"options": [
							"True",
							"False",
						],
						"correct": 0,
						"explanation": "If demand doesn't have to share one limited tower, it won't compete for that tower's bandwidth.",
						"hint": "Think about what happens when buildings don't have to share.",
					},
				],
			},
			"measure_speed": {
				"title": "Measure the speed",
				"done": "You can compare connection speeds using Mbps.",
				"questions": [
					{
						"question": "Internet speed is often measured in...",
						"options": [
							"Mbps (megabits per second)",
							"Kilograms",
							"Liters",
							"Degrees",
						],
						"correct": 0,
						"explanation": "Mbps measures how much data moves per second.",
						"hint": "Think about data moving per second.",
					},
					{
						"question": "Which is faster, 10 Mbps or 100 Mbps?",
						"options": [
							"100 Mbps",
							"10 Mbps",
							"They are the same",
							"Neither",
						],
						"correct": 0,
						"explanation": "A higher Mbps number means more data per second.",
						"hint": "Compare the two numbers.",
					},
					{
						"question": "A livestream needs a steady amount of bandwidth. If bandwidth drops below what it needs, what happens?",
						"options": [
							"The video may freeze or lower its quality",
							"The video gets brighter",
							"The tower falls down",
							"Nothing happens",
						],
						"correct": 0,
						"explanation": "Without enough bandwidth, video quality usually suffers.",
						"hint": "Think about what you've seen happen to a slow stream.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how bandwidth grew alongside internet use.",
				"questions": [
					{
						"question": "Old dial-up internet had ___ bandwidth than today's fiber internet.",
						"options": [
							"Much less",
							"Much more",
							"Exactly the same",
							"Unlimited",
						],
						"correct": 0,
						"explanation": "Dial-up bandwidth was tiny compared to modern fiber.",
						"hint": "Think about how slow old dial-up sounded.",
					},
					{
						"question": "Which of these typically has the most bandwidth today?",
						"options": [
							"Fiber optic cable",
							"A landline phone call",
							"A telegraph",
							"A letter",
						],
						"correct": 0,
						"explanation": "Fiber optic cables carry huge amounts of data very fast.",
						"hint": "Think about modern high-speed internet.",
					},
					{
						"question": "As more people streamed video over the years, internet providers had to...",
						"options": [
							"Increase available bandwidth",
							"Remove the internet",
							"Use fewer cables",
							"Slow down on purpose",
						],
						"correct": 0,
						"explanation": "Growing demand pushed providers to increase bandwidth.",
						"hint": "Think about what more demand requires.",
					},
				],
			},
		},
	},
	5: {
		"title": "Keep It Moving",
		"topic": "Lag",
		"summary": [
			"• Main: learn what lag is, what causes it, and how to fix it",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "Bandwidth's balanced, but Gamer Jun says his calls still feel behind, even with plenty of bandwidth to spare.",
			},
			{
				"speaker": "Gamer Jun",
				"text": "I've got bars and speed, but everything I do online feels a half-second late. It's driving me crazy.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "That's lag, Trainee. A delay, not a shortage. Let's figure out where it's coming from.",
			},
		],
		"outro": [
			{
				"speaker": "Gamer Jun",
				"text": "It feels instant now! Thanks, Trainee.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Great work trimming that delay. Now, out at the harbor, Kuya Migs says his signal barely reaches the docks at all.",
			},
		],
		"outro_by_stars": {
			1: "The lag is gone. Side quests are still open whenever you like.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You tracked down every source of delay. Well done, Trainee.",
		},
		"main": [
			{
				"id": "what_is_lag",
				"title": "What is lag?",
				"desc": "Learn that lag is a delay, measured in milliseconds.",
			},
			{
				"id": "causes_of_lag",
				"title": "Causes of lag",
				"desc": "Find out what makes a connection feel delayed.",
			},
			{
				"id": "fix_the_lag",
				"title": "Fix the lag",
				"desc": "Pick the right fix for Gamer Jun's delayed connection.",
			},
		],
		"side": [
			{
				"id": "ping_test",
				"title": "The ping test",
				"desc": "Learn what a ping test actually measures.",
				"needs_puzzle": false,
				"unlock_after": "what_is_lag",
			},
			{
				"id": "relay_it",
				"title": "Relay it",
				"desc": "See how a repeater helps reduce lag over long distances.",
				"needs_puzzle": false,
				"unlock_after": "causes_of_lag",
			},
			{
				"id": "video_call_fix",
				"title": "Fix the video call",
				"desc": "Diagnose why Coach Bea's video call keeps freezing.",
				"needs_puzzle": false,
				"unlock_after": "fix_the_lag",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about lag over satellites and fiber.",
				"needs_puzzle": false,
			},
		],
		"terms": {
			"what_is_lag": {
				"title": "Latency",
				"text": "Latency (lag) is the delay between doing something online and seeing the result.",
			},
			"causes_of_lag": {
				"title": "Delay",
				"text": "Delay can come from long distances, too many hops, or congestion.",
			},
			"fix_the_lag": {
				"title": "Relay",
				"text": "A relay (repeater) strengthens a weak signal so it doesn't need to be resent, which helps cut delay.",
			},
		},
		"quiz_sets": {
			"what_is_lag": {
				"title": "What is lag?",
				"done": "You know what lag really is.",
				"questions": [
					{
						"question": "Lag is best described as...",
						"options": [
							"A delay between an action and its result online",
							"A type of cable",
							"A discount on internet bills",
							"A kind of tower",
						],
						"correct": 0,
						"explanation": "Lag is the delay you notice between doing something online and seeing the result.",
						"hint": "Think about waiting for something to happen after you act.",
					},
					{
						"question": "Lag is often measured in...",
						"options": [
							"Milliseconds (ms)",
							"Kilograms",
							"Liters",
							"Meters",
						],
						"correct": 0,
						"explanation": "Lag is measured in milliseconds, since it's about time.",
						"hint": "Think about very short units of time.",
					},
					{
						"question": "In an online game, high lag usually feels like...",
						"options": [
							"Actions happen late or freeze briefly",
							"Everything gets brighter",
							"The screen changes color",
							"Nothing changes",
						],
						"correct": 0,
						"explanation": "High lag makes actions feel delayed or stuck.",
						"hint": "Think about what a delay actually feels like.",
					},
				],
			},
			"causes_of_lag": {
				"title": "Causes of lag",
				"done": "You know what usually causes lag.",
				"questions": [
					{
						"question": "Which is a common cause of lag?",
						"options": [
							"The message must travel a long distance",
							"The tower is painted blue",
							"The building has flowers",
							"The Wi-Fi password is short",
						],
						"correct": 0,
						"explanation": "Longer distances and more hops usually add delay.",
						"hint": "Think about how far a signal has to travel.",
					},
					{
						"question": "Congestion (too much traffic) can also cause...",
						"options": [
							"More lag",
							"Less lag",
							"No effect",
							"Faster speeds",
						],
						"correct": 0,
						"explanation": "Congestion adds waiting time, which shows up as lag.",
						"hint": "Think about a crowded road slowing everyone down.",
					},
					{
						"question": "True or false: more hops on a path usually means less lag.",
						"options": [
							"False",
							"True",
						],
						"correct": 0,
						"explanation": "More hops usually add more delay, not less.",
						"hint": "Think back to Chapter 3's lesson on hops.",
					},
				],
			},
			"fix_the_lag": {
				"title": "Fix the lag",
				"done": "You can choose the right fix for a laggy connection.",
				"questions": [
					{
						"question": "Gamer Jun's connection lags because his message takes many hops. What could help?",
						"options": [
							"A shorter, more direct path",
							"A longer path",
							"Turning off the router",
							"Removing the modem",
						],
						"correct": 0,
						"explanation": "A shorter path with fewer hops usually reduces delay.",
						"hint": "Think about reducing the number of stops.",
					},
					{
						"question": "If a signal is weak over a long distance, which device helps reduce the extra delay?",
						"options": [
							"A repeater",
							"A calculator",
							"A doorbell",
							"A flashlight",
						],
						"correct": 0,
						"explanation": "A repeater strengthens a weak signal so it doesn't need to be resent.",
						"hint": "Think back to Chapter 2's devices.",
					},
					{
						"question": "If congestion is causing lag, which earlier fix could help here too?",
						"options": [
							"Sharing the load across more towers",
							"Deleting all the buildings",
							"Turning off the internet",
							"Ignoring the problem",
						],
						"correct": 0,
						"explanation": "Load balancing from Chapter 4 also helps reduce lag caused by congestion.",
						"hint": "Think back to Chapter 4.",
					},
				],
			},
			"ping_test": {
				"title": "The ping test",
				"done": "You know what a ping test tells you.",
				"questions": [
					{
						"question": "A 'ping' test measures...",
						"options": [
							"How long it takes a message to go and come back",
							"How loud a sound is",
							"How heavy a device is",
							"How bright a screen is",
						],
						"correct": 0,
						"explanation": "A ping test measures the round-trip time of a message.",
						"hint": "Think about sending something and waiting for a reply.",
					},
					{
						"question": "A ping of 20ms compared to a ping of 200ms is...",
						"options": [
							"Much faster",
							"Much slower",
							"The same",
							"Impossible to compare",
						],
						"correct": 0,
						"explanation": "A lower ping means less delay.",
						"hint": "Compare the two numbers.",
					},
					{
						"question": "True or false: a lower ping usually means less lag.",
						"options": [
							"True",
							"False",
						],
						"correct": 0,
						"explanation": "Lower ping means less round-trip delay, which means less lag.",
						"hint": "Think about what the ping number represents.",
					},
				],
			},
			"relay_it": {
				"title": "Relay it",
				"done": "You know how a relay helps cut down on lag.",
				"questions": [
					{
						"question": "What does a network relay (repeater) mainly help with over long distances?",
						"options": [
							"Keeping the signal strong so it doesn't need retransmitting",
							"Changing the Wi-Fi password",
							"Painting the tower",
							"Adding more buildings",
						],
						"correct": 0,
						"explanation": "A repeater keeps a signal strong enough that it doesn't need to be resent.",
						"hint": "Think about strengthening a weak signal.",
					},
					{
						"question": "Without a relay, a weak signal over a long distance might need to be sent again, which...",
						"options": [
							"Adds more lag",
							"Removes all lag",
							"Makes the signal purple",
							"Deletes the message",
						],
						"correct": 0,
						"explanation": "Resending data takes extra time, which adds lag.",
						"hint": "Think about what happens when you have to repeat yourself.",
					},
					{
						"question": "Where would a relay be most useful?",
						"options": [
							"Between two points that are far apart",
							"Right next to the source",
							"Nowhere, they're never useful",
							"Only underwater",
						],
						"correct": 0,
						"explanation": "A relay helps most when a signal has to travel a long distance.",
						"hint": "Think about where signals get weak.",
					},
				],
			},
			"video_call_fix": {
				"title": "Fix the video call",
				"done": "You can diagnose why a video call feels laggy.",
				"questions": [
					{
						"question": "A video call keeps freezing for Coach Bea. Bandwidth looks fine but the path has many hops. What's the likely fix?",
						"options": [
							"Find a shorter path",
							"Add more buildings",
							"Turn off the camera forever",
							"Remove the router",
						],
						"correct": 0,
						"explanation": "A shorter path with fewer hops usually reduces delay.",
						"hint": "Think about the number of stops the call takes.",
					},
					{
						"question": "If the call lags only when many people are online at once, what's the likely cause?",
						"options": [
							"Congestion adding delay",
							"The weather",
							"The color of the walls",
							"Nothing, it's random",
						],
						"correct": 0,
						"explanation": "Congestion from too much traffic can add lag.",
						"hint": "Think about a busy time of day.",
					},
					{
						"question": "Which combination best reduces lag for a video call?",
						"options": [
							"Shorter path and less congestion",
							"Longer path and more congestion",
							"No internet at all",
							"A broken cable",
						],
						"correct": 0,
						"explanation": "Both a shorter path and less congestion help reduce lag.",
						"hint": "Think about combining both fixes.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how lag has changed as technology improved.",
				"questions": [
					{
						"question": "Old satellite internet often had ___ lag compared to modern fiber.",
						"options": [
							"Much higher",
							"Much lower",
							"The same",
							"None at all",
						],
						"correct": 0,
						"explanation": "Signals to and from satellites travel a very long distance, adding delay.",
						"hint": "Think about how far a satellite is.",
					},
					{
						"question": "Fiber optic cables reduced lag mainly because they...",
						"options": [
							"Send data as fast light signals over short, direct paths",
							"Are painted a special color",
							"Use paper instead of light",
							"Are always underwater",
						],
						"correct": 0,
						"explanation": "Fiber sends data as light very quickly over efficient paths.",
						"hint": "Think about how fast light travels.",
					},
					{
						"question": "As online gaming grew popular, low lag became important because...",
						"options": [
							"Players need quick, accurate responses",
							"Games need bigger screens",
							"Games became more colorful",
							"Lag makes games load faster",
						],
						"correct": 0,
						"explanation": "Fast, accurate responses matter a lot in real-time games.",
						"hint": "Think about reacting quickly in a game.",
					},
				],
			},
		},
	},
	6: {
		"title": "Covering the Gaps",
		"topic": "Wireless",
		"summary": [
			"• Main: learn wireless basics, find dead zones, then cover the docks",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"puzzle": {
			"main_quest": "cover_the_docks",
			"budget_quest": "budget",
			"notes_quest": "ask_around",
		},
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "Out at the harbor, there's a dead zone right where the fishing boats dock.",
			},
			{
				"speaker": "Kuya Migs",
				"text": "Radio signal reaches the harbor fine, but past the breakwater, it's nothing. My friend Ka Boy can't call in his catch.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Time to learn about wireless coverage, then close that dead zone.",
			},
		],
		"outro": [
			{
				"speaker": "Kuya Migs",
				"text": "Ka Boy just called in. Signal reaches all the way to the breakwater now!",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Coverage sorted. Something's been bothering me, though. City Hall reported some strange traffic trying to sneak into their records.",
			},
		],
		"outro_by_stars": {
			1: "The dead zone is covered. Side quests are still open whenever you like.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You closed every gap in the coverage. Well done, Trainee.",
		},
		"main": [
			{
				"id": "what_is_wireless",
				"title": "What is wireless?",
				"desc": "Learn how wireless signals travel through the air.",
			},
			{
				"id": "dead_zones",
				"title": "Find the dead zones",
				"desc": "Learn what causes a dead zone in wireless coverage.",
			},
			{
				"id": "cover_the_docks",
				"title": "Cover the docks",
				"desc": "Place towers so every building has wireless coverage.",
				"kind": "puzzle",
			},
		],
		"side": [
			{
				"id": "ask_around",
				"title": "Ask around",
				"desc": "Tap each building and hear how coverage affected them.",
				"needs_puzzle": true,
				"unlock_after": "cover_the_docks",
				"show_notes_progress": true,
			},
			{
				"id": "budget",
				"title": "Lean network",
				"desc": "Cover the docks using as few towers as you can.",
				"needs_puzzle": true,
				"unlock_after": "cover_the_docks",
				"show_budget": true,
			},
			{
				"id": "signal_strength",
				"title": "Signal strength",
				"desc": "Learn what those signal bars on a phone actually mean.",
				"needs_puzzle": false,
				"unlock_after": "what_is_wireless",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about how wireless technology improved.",
				"needs_puzzle": false,
			},
		],
		"notes": {
			"Building2": {
				"speaker": "Aling Rosa",
				"line": "My phone finally gets a signal on the porch now, not just inside.",
				"title": "Aling Rosa",
				"text": "Coverage can be weaker in some spots than others, even in the same building.",
			},
			"Apartments2": {
				"speaker": "Kuya Migs",
				"line": "The whole harbor has signal now, all the way to the breakwater.",
				"title": "Kuya Migs",
				"text": "A tower's coverage reaches only so far before the signal fades.",
			},
			"Apartments3": {
				"speaker": "Ate Joy",
				"line": "Even the far end of the school yard has Wi-Fi now.",
				"title": "Ate Joy",
				"text": "Extra coverage nearby can close a dead zone.",
			},
			"Apartments4": {
				"speaker": "Mang Tonio",
				"line": "My shop's back room used to have no signal at all. Not anymore.",
				"title": "Mang Tonio",
				"text": "Walls and distance can both weaken a wireless signal.",
			},
		},
		"terms": {
			"what_is_wireless": {
				"title": "Wireless",
				"text": "Wireless connections carry signals through the air using radio waves.",
			},
			"dead_zones": {
				"title": "Dead zone",
				"text": "A dead zone is a place where wireless signal doesn't reach well.",
			},
			"cover_the_docks": {
				"title": "Coverage radius",
				"text": "A tower's coverage radius is the area around it where its signal reaches.",
			},
		},
		"quiz_sets": {
			"what_is_wireless": {
				"title": "What is wireless?",
				"done": "You understand the basics of wireless signals.",
				"questions": [
					{
						"question": "Wireless connections carry signals through...",
						"options": [
							"The air, using radio waves",
							"Underground pipes",
							"Only glass cables",
							"Sunlight only",
						],
						"correct": 0,
						"explanation": "Wireless signals travel through the air as radio waves.",
						"hint": "Think about what doesn't need a cable.",
					},
					{
						"question": "Which of these is a wireless connection?",
						"options": [
							"Wi-Fi",
							"A wired ethernet cable",
							"A landline phone cord",
							"A fiber cable",
						],
						"correct": 0,
						"explanation": "Wi-Fi carries data through the air without a cable.",
						"hint": "Which of these has no physical cable to your device?",
					},
					{
						"question": "Wireless signals can be blocked by...",
						"options": [
							"Thick walls and long distances",
							"Nothing at all",
							"Only rain",
							"Only at night",
						],
						"correct": 0,
						"explanation": "Walls and distance can both weaken or block a wireless signal.",
						"hint": "Think about what gets in the way of a signal.",
					},
				],
			},
			"dead_zones": {
				"title": "Find the dead zones",
				"done": "You can spot what causes a dead zone.",
				"questions": [
					{
						"question": "A 'dead zone' is a place where...",
						"options": [
							"Wireless signal doesn't reach well",
							"Everyone is asleep",
							"The internet is free",
							"The tower is painted",
						],
						"correct": 0,
						"explanation": "A dead zone has weak or no wireless coverage.",
						"hint": "Think about what happens when you have no bars on your phone.",
					},
					{
						"question": "What usually causes a dead zone?",
						"options": [
							"Being too far from a tower or blocked by obstacles",
							"Having too much bandwidth",
							"Using a wired cable",
							"Using a modem",
						],
						"correct": 0,
						"explanation": "Distance and obstacles both weaken wireless coverage.",
						"hint": "Think about what blocks or fades a signal.",
					},
					{
						"question": "The best way to fix a dead zone is often to...",
						"options": [
							"Add coverage nearby, like another tower",
							"Remove all towers",
							"Turn off Wi-Fi everywhere",
							"Paint the walls",
						],
						"correct": 0,
						"explanation": "Adding coverage nearby closes the gap.",
						"hint": "Think about giving that area its own signal source.",
					},
				],
			},
			"signal_strength": {
				"title": "Signal strength",
				"done": "You know what signal strength actually shows.",
				"questions": [
					{
						"question": "The 'bars' on a phone usually show...",
						"options": [
							"How strong the wireless signal is",
							"How much battery is left",
							"How many apps are open",
							"How loud the phone is",
						],
						"correct": 0,
						"explanation": "Signal bars represent wireless signal strength.",
						"hint": "Think about what those bars usually go up or down with.",
					},
					{
						"question": "Moving closer to a tower usually makes signal strength...",
						"options": [
							"Stronger",
							"Weaker",
							"The same",
							"Disappear",
						],
						"correct": 0,
						"explanation": "Signals are usually stronger closer to their source.",
						"hint": "Think about standing right next to something loud.",
					},
					{
						"question": "A wall between you and the tower usually makes the signal...",
						"options": [
							"Weaker",
							"Stronger",
							"Faster",
							"Wireless-only",
						],
						"correct": 0,
						"explanation": "Obstacles like walls usually weaken wireless signals.",
						"hint": "Think about what happens to sound through a wall.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how wireless technology has grown over time.",
				"questions": [
					{
						"question": "Which came first?",
						"options": [
							"Basic mobile calls (early wireless)",
							"High-speed 5G internet",
							"Video streaming on phones",
							"Smartphone app stores",
						],
						"correct": 0,
						"explanation": "Basic mobile calls came long before high-speed wireless internet.",
						"hint": "Think about the very first mobile phones.",
					},
					{
						"question": "Each new generation of wireless technology usually brought...",
						"options": [
							"Faster speeds and more capacity",
							"Less coverage",
							"Higher lag only",
							"No changes",
						],
						"correct": 0,
						"explanation": "Newer generations generally improved speed and capacity.",
						"hint": "Think about how phones got faster over time.",
					},
					{
						"question": "Today's wireless networks support many more devices than early ones because they...",
						"options": [
							"Improved technology over time",
							"Removed all towers",
							"Stopped using radio waves",
							"Became wired instead",
						],
						"correct": 0,
						"explanation": "Wireless technology has steadily improved over time.",
						"hint": "Think about how much has changed since the first mobile phones.",
					},
				],
			},
		},
	},
	7: {
		"title": "Locks and Alarms",
		"topic": "Network security",
		"summary": [
			"• Main: learn about security, spot threats, then lock it down",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "City Hall's records had a scare. Some suspicious traffic tried to slip through.",
			},
			{
				"speaker": "Locksmith Nena",
				"text": "Good thing I caught it. I'm Nena. Locks are my trade, but these days that includes digital locks too.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Learn how to spot and block that kind of traffic, then help Nena lock things down.",
			},
		],
		"outro": [
			{
				"speaker": "Locksmith Nena",
				"text": "City Hall's records are secure now. Nice catch, Trainee.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "With that settled, let's look at how this whole district is laid out. I think its shape might be part of a problem elsewhere.",
			},
		],
		"outro_by_stars": {
			1: "City Hall is secure. Side quests are still open whenever you like.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You locked down every weak spot in town. Well done, Trainee.",
		},
		"main": [
			{
				"id": "what_is_security",
				"title": "What is network security?",
				"desc": "Learn how firewalls and passwords protect a network.",
			},
			{
				"id": "spot_the_threat",
				"title": "Spot the threat",
				"desc": "Learn to recognize traffic that could be harmful.",
			},
			{
				"id": "lock_it_down",
				"title": "Lock it down",
				"desc": "Decide how to protect City Hall's connection.",
			},
		],
		"side": [
			{
				"id": "password_strength",
				"title": "Password strength",
				"desc": "Learn what makes a password strong or weak.",
				"needs_puzzle": false,
				"unlock_after": "what_is_security",
			},
			{
				"id": "phishing_or_not",
				"title": "Phishing or not?",
				"desc": "Practice spotting a suspicious message.",
				"needs_puzzle": false,
				"unlock_after": "spot_the_threat",
			},
			{
				"id": "firewall_basics",
				"title": "Firewall basics",
				"desc": "Learn how a firewall decides what to block.",
				"needs_puzzle": false,
				"unlock_after": "lock_it_down",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about how network security grew.",
				"needs_puzzle": false,
			},
		],
		"terms": {
			"what_is_security": {
				"title": "Firewall",
				"text": "A firewall blocks harmful traffic while letting good traffic through.",
			},
			"spot_the_threat": {
				"title": "Threat",
				"text": "A threat is traffic that is trying to cause harm or sneak through unnoticed.",
			},
			"lock_it_down": {
				"title": "Password",
				"text": "A password proves that you're allowed to access something.",
			},
		},
		"quiz_sets": {
			"what_is_security": {
				"title": "What is network security?",
				"done": "You understand the basics of network security.",
				"questions": [
					{
						"question": "A firewall's main job is to...",
						"options": [
							"Block harmful traffic while letting good traffic through",
							"Cook food",
							"Paint buildings",
							"Play music",
						],
						"correct": 0,
						"explanation": "A firewall filters traffic, blocking harmful traffic and allowing good traffic.",
						"hint": "Think about a guard checking who can enter.",
					},
					{
						"question": "Why does a network need security at all?",
						"options": [
							"To protect it from harmful or unwanted traffic",
							"To make it slower",
							"To use more electricity",
							"To remove all connections",
						],
						"correct": 0,
						"explanation": "Security protects a network from harmful traffic.",
						"hint": "Think about what could go wrong without protection.",
					},
					{
						"question": "A password is one way to...",
						"options": [
							"Prove you're allowed to access something",
							"Speed up the internet",
							"Add more bandwidth",
							"Paint a tower",
						],
						"correct": 0,
						"explanation": "A password proves you have permission to access something.",
						"hint": "Think about what a password is checked against.",
					},
				],
			},
			"spot_the_threat": {
				"title": "Spot the threat",
				"done": "You can recognize traffic that might be a threat.",
				"questions": [
					{
						"question": "A 'threat' on a network is best described as...",
						"options": [
							"Data trying to cause harm or sneak through",
							"A slow delivery truck",
							"A broken cable",
							"A type of bandwidth",
						],
						"correct": 0,
						"explanation": "A threat is traffic trying to cause harm or bypass protection.",
						"hint": "Think about what a firewall is trying to catch.",
					},
					{
						"question": "If traffic suddenly floods in from an unknown, unexpected source, that could be a sign of...",
						"options": [
							"A possible threat worth checking",
							"A normal, safe update",
							"Nothing to worry about ever",
							"A faster connection",
						],
						"correct": 0,
						"explanation": "Sudden, unexpected traffic is worth investigating.",
						"hint": "Think about what looks out of place.",
					},
					{
						"question": "What should a firewall do when it sees traffic matching a known threat pattern?",
						"options": [
							"Block it",
							"Let it through immediately",
							"Delete the whole network",
							"Ignore it forever",
						],
						"correct": 0,
						"explanation": "A firewall blocks traffic that matches known threat patterns.",
						"hint": "Think about the firewall's main job.",
					},
				],
			},
			"lock_it_down": {
				"title": "Lock it down",
				"done": "You can decide how to protect a connection.",
				"questions": [
					{
						"question": "City Hall's records need extra protection. What's a reasonable first step?",
						"options": [
							"Add a firewall and a strong password",
							"Remove all security",
							"Share the password publicly",
							"Turn off the connection forever",
						],
						"correct": 0,
						"explanation": "A firewall and a strong password are a reasonable first line of defense.",
						"hint": "Think about basic protection steps.",
					},
					{
						"question": "A weak, easy-to-guess password makes a connection...",
						"options": [
							"Less secure",
							"More secure",
							"Faster",
							"Wireless",
						],
						"correct": 0,
						"explanation": "A weak password makes it easier for someone to break in.",
						"hint": "Think about how easy it would be to guess.",
					},
					{
						"question": "True or false: even a small business connection can benefit from basic security like a password.",
						"options": [
							"True",
							"False",
						],
						"correct": 0,
						"explanation": "Any connection can benefit from basic protection.",
						"hint": "Think about whether size matters for needing protection.",
					},
				],
			},
			"password_strength": {
				"title": "Password strength",
				"done": "You know what makes a password strong.",
				"questions": [
					{
						"question": "Which password is generally stronger?",
						"options": [
							"A long mix of letters, numbers and symbols",
							"The word 'password'",
							"Your own name",
							"123456",
						],
						"correct": 0,
						"explanation": "A long, varied password is much harder to guess.",
						"hint": "Think about which is easiest for someone else to guess.",
					},
					{
						"question": "Reusing the exact same password everywhere is...",
						"options": [
							"Risky, since one leak can affect many accounts",
							"Always perfectly safe",
							"Required by every website",
							"The fastest way to log in",
						],
						"correct": 0,
						"explanation": "Reusing passwords means one leak can affect everything.",
						"hint": "Think about what happens if just one site is compromised.",
					},
					{
						"question": "A password manager mainly helps you...",
						"options": [
							"Keep track of strong, unique passwords",
							"Delete your accounts",
							"Slow down your internet",
							"Remove your firewall",
						],
						"correct": 0,
						"explanation": "A password manager helps you use strong, different passwords everywhere.",
						"hint": "Think about what's hard to do manually.",
					},
				],
			},
			"phishing_or_not": {
				"title": "Phishing or not?",
				"done": "You can spot the signs of a suspicious message.",
				"questions": [
					{
						"question": "A message claims to be from your bank and urgently asks for your password by email. This is most likely...",
						"options": [
							"A phishing attempt, since real banks don't ask this way",
							"Completely normal",
							"A firmware update",
							"A firewall",
						],
						"correct": 0,
						"explanation": "Real organizations don't usually ask for your password directly like this.",
						"hint": "Think about how a real bank would normally contact you.",
					},
					{
						"question": "What's a good habit before clicking a link in an unexpected message?",
						"options": [
							"Check if the sender and link look legitimate first",
							"Click immediately",
							"Share your password to test it",
							"Turn off your device forever",
						],
						"correct": 0,
						"explanation": "Checking first helps you avoid suspicious links.",
						"hint": "Think about pausing before you act.",
					},
					{
						"question": "If a message seems suspicious, a safe action is to...",
						"options": [
							"Not click and verify another way",
							"Reply with your password",
							"Forward it to everyone",
							"Ignore your firewall",
						],
						"correct": 0,
						"explanation": "Verifying through another channel is safer than clicking blindly.",
						"hint": "Think about confirming before trusting a link.",
					},
				],
			},
			"firewall_basics": {
				"title": "Firewall basics",
				"done": "You know how a firewall decides what to let through.",
				"questions": [
					{
						"question": "A firewall works a bit like...",
						"options": [
							"A security guard checking who can enter",
							"A painter",
							"A delivery truck",
							"A musician",
						],
						"correct": 0,
						"explanation": "A firewall checks traffic much like a guard checks visitors.",
						"hint": "Think about someone checking IDs at a door.",
					},
					{
						"question": "Which is a firewall more likely to block?",
						"options": [
							"Traffic matching a known harmful pattern",
							"A normal webpage request",
							"A regular email you expect",
							"A song you're streaming",
						],
						"correct": 0,
						"explanation": "A firewall targets traffic that matches harmful patterns.",
						"hint": "Think about which of these looks suspicious.",
					},
					{
						"question": "True or false: a firewall can help block unwanted traffic while still allowing normal traffic through.",
						"options": [
							"True",
							"False",
						],
						"correct": 0,
						"explanation": "A good firewall filters traffic instead of blocking everything.",
						"hint": "Think about the balance a firewall tries to strike.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how network security grew alongside the internet.",
				"questions": [
					{
						"question": "In the internet's early days, security was generally...",
						"options": [
							"Much weaker than it is today",
							"Much stronger than today",
							"Exactly the same as today",
							"Not needed at all",
						],
						"correct": 0,
						"explanation": "Early networks had far less security than modern ones.",
						"hint": "Think about how small and trusted early networks were.",
					},
					{
						"question": "As more people went online, the need for security...",
						"options": [
							"Increased",
							"Disappeared",
							"Stayed exactly the same",
							"Became unnecessary",
						],
						"correct": 0,
						"explanation": "More users and more valuable data meant more need for security.",
						"hint": "Think about what more people online usually attracts.",
					},
					{
						"question": "Firewalls and passwords became more common over time because...",
						"options": [
							"More threats appeared as networks grew",
							"The internet got slower",
							"Towers got taller",
							"Bandwidth disappeared",
						],
						"correct": 0,
						"explanation": "Growing networks attracted more threats, driving the need for protection.",
						"hint": "Think about what growth usually brings with it.",
					},
				],
			},
		},
	},
	8: {
		"title": "Shapes of a Network",
		"topic": "Topology",
		"summary": [
			"• Main: learn what topology is, the simple shapes, then pick one",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "Architect Dado's new office district keeps having connection headaches whenever one office has an issue.",
			},
			{
				"speaker": "Architect Dado",
				"text": "I'm Dado. I plan how the buildings connect, not just how they look. I think we picked the wrong shape for this layout.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Let's learn the simple shapes a network can take, then help Dado choose the right one.",
			},
		],
		"outro": [
			{
				"speaker": "Architect Dado",
				"text": "That layout works so much better. Thanks for the lesson, Trainee.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Good instincts. Now, Dispatcher 201 at the hospital has an urgent problem. An ambulance call keeps getting stuck behind a livestream.",
			},
		],
		"outro_by_stars": {
			1: "The district has a working layout now. Side quests are still open whenever you like.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You know every simple shape a network can take. Well done, Trainee.",
		},
		"main": [
			{
				"id": "what_is_topology",
				"title": "What is topology?",
				"desc": "Learn that topology is the shape of how devices connect.",
			},
			{
				"id": "types_of_topology",
				"title": "The simple shapes",
				"desc": "Learn the basics of star, ring, and bus layouts.",
			},
			{
				"id": "pick_a_shape",
				"title": "Pick a shape",
				"desc": "Help Architect Dado choose the best layout for the district.",
			},
		],
		"side": [
			{
				"id": "star_topology",
				"title": "Star topology",
				"desc": "Learn more about connecting through one central hub.",
				"needs_puzzle": false,
				"unlock_after": "types_of_topology",
			},
			{
				"id": "ring_topology",
				"title": "Ring topology",
				"desc": "Learn more about connecting devices in a loop.",
				"needs_puzzle": false,
				"unlock_after": "types_of_topology",
			},
			{
				"id": "bus_topology",
				"title": "Bus topology",
				"desc": "Learn more about connecting devices along one shared line.",
				"needs_puzzle": false,
				"unlock_after": "types_of_topology",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about how office networks were laid out.",
				"needs_puzzle": false,
			},
		],
		"terms": {
			"what_is_topology": {
				"title": "Topology",
				"text": "Topology is the shape or layout of how devices in a network are connected.",
			},
			"types_of_topology": {
				"title": "Star, ring, and bus",
				"text": "Star connects devices to one hub, ring connects them in a loop, and bus connects them along one shared line.",
			},
			"pick_a_shape": {
				"title": "Hub",
				"text": "A hub is the central point that devices connect to in a star topology.",
			},
		},
		"quiz_sets": {
			"what_is_topology": {
				"title": "What is topology?",
				"done": "You understand what topology means.",
				"questions": [
					{
						"question": "Network topology refers to...",
						"options": [
							"The shape or layout of how devices are connected",
							"The color of cables",
							"The price of internet",
							"The brand of router",
						],
						"correct": 0,
						"explanation": "Topology describes the layout of connections in a network.",
						"hint": "Think about a map of connections.",
					},
					{
						"question": "Why does the shape of a network matter?",
						"options": [
							"It affects how messages travel and what happens if one link breaks",
							"It changes the internet's color",
							"It changes the price only",
							"It has no effect at all",
						],
						"correct": 0,
						"explanation": "The shape affects both message paths and how failures spread.",
						"hint": "Think about what changes if one connection breaks.",
					},
					{
						"question": "A simple way to think of topology is...",
						"options": [
							"A map of how computers are connected",
							"A type of food",
							"A kind of password",
							"A musical instrument",
						],
						"correct": 0,
						"explanation": "Topology is essentially a map of connections.",
						"hint": "Think about drawing the connections on paper.",
					},
				],
			},
			"types_of_topology": {
				"title": "The simple shapes",
				"done": "You know the three simple network shapes.",
				"questions": [
					{
						"question": "In a star topology, every device connects to...",
						"options": [
							"One central point, like a hub",
							"Every other device directly",
							"No one",
							"Only its neighbor",
						],
						"correct": 0,
						"explanation": "A star topology connects every device to one central hub.",
						"hint": "Think about lines meeting at one center point.",
					},
					{
						"question": "In a ring topology, devices are connected...",
						"options": [
							"In a circle, each to the next",
							"In one central hub",
							"Randomly with no pattern",
							"Not connected at all",
						],
						"correct": 0,
						"explanation": "A ring topology forms a closed loop of connections.",
						"hint": "Think about a circle shape.",
					},
					{
						"question": "In a bus topology, all devices share...",
						"options": [
							"One single main line",
							"A separate line each",
							"No connection",
							"Only wireless signals",
						],
						"correct": 0,
						"explanation": "A bus topology connects all devices to one shared line.",
						"hint": "Think about one long line everyone connects to.",
					},
				],
			},
			"pick_a_shape": {
				"title": "Pick a shape",
				"done": "You can choose a sensible layout for a small network.",
				"questions": [
					{
						"question": "Architect Dado wants an easy way to add or remove offices without disrupting everyone. Which shape fits best?",
						"options": [
							"Star, through one central hub",
							"Ring only",
							"No topology at all",
							"Random connections",
						],
						"correct": 0,
						"explanation": "A star topology lets you add or remove a device by just plugging into the hub.",
						"hint": "Think about which layout is easiest to change.",
					},
					{
						"question": "If the central hub in a star topology fails, what happens?",
						"options": [
							"The whole network can go down",
							"Nothing happens at all",
							"It gets faster",
							"It becomes wireless",
						],
						"correct": 0,
						"explanation": "A failed hub can disconnect every device relying on it.",
						"hint": "Think about what the hub is responsible for.",
					},
					{
						"question": "In a ring topology, if one connection breaks, what can happen?",
						"options": [
							"It can disrupt the whole ring unless there's a backup path",
							"Nothing changes at all",
							"The ring gets bigger",
							"It becomes a star automatically",
						],
						"correct": 0,
						"explanation": "A broken link in a simple ring can disrupt the whole loop.",
						"hint": "Think about what happens to a circle with one gap.",
					},
				],
			},
			"star_topology": {
				"title": "Star topology",
				"done": "You know the strengths and weaknesses of star topology.",
				"questions": [
					{
						"question": "The 'center' of a star topology is often a...",
						"options": [
							"Hub or switch",
							"Random device",
							"Nothing",
							"A password",
						],
						"correct": 0,
						"explanation": "A hub or switch usually sits at the center of a star.",
						"hint": "Think back to Chapter 2's devices.",
					},
					{
						"question": "A benefit of star topology is...",
						"options": [
							"Easy to add new devices at the hub",
							"It never needs a hub",
							"It has no central point",
							"It's always wireless",
						],
						"correct": 0,
						"explanation": "Adding a device to a star just means plugging it into the hub.",
						"hint": "Think about how simple it is to add a new connection.",
					},
					{
						"question": "A downside of star topology is...",
						"options": [
							"If the hub fails, connected devices lose their link",
							"It's impossible to set up",
							"It only works with 2 devices",
							"It requires no hub at all",
						],
						"correct": 0,
						"explanation": "The hub is a single point that everything depends on.",
						"hint": "Think about what all the devices rely on.",
					},
				],
			},
			"ring_topology": {
				"title": "Ring topology",
				"done": "You know the strengths and weaknesses of ring topology.",
				"questions": [
					{
						"question": "In a ring, data usually travels...",
						"options": [
							"Around the circle from one device to the next",
							"Directly to a central hub",
							"Nowhere",
							"Only outward, never around",
						],
						"correct": 0,
						"explanation": "Data passes around the ring from device to device.",
						"hint": "Think about the loop shape.",
					},
					{
						"question": "A ring topology's shape is best described as...",
						"options": [
							"A closed loop",
							"A straight line",
							"A single point",
							"A random web",
						],
						"correct": 0,
						"explanation": "A ring forms a closed loop of connections.",
						"hint": "Think about the name itself: ring.",
					},
					{
						"question": "One challenge with a simple ring is...",
						"options": [
							"One broken link can affect the whole loop",
							"It always doubles the speed",
							"It needs no cables at all",
							"It is always wireless",
						],
						"correct": 0,
						"explanation": "A single break can disrupt the entire loop.",
						"hint": "Think about what happens to a chain with one broken link.",
					},
				],
			},
			"bus_topology": {
				"title": "Bus topology",
				"done": "You know the strengths and weaknesses of bus topology.",
				"questions": [
					{
						"question": "In a bus topology, all devices connect to...",
						"options": [
							"One shared main line",
							"Their own separate hub each",
							"Nothing",
							"Only a ring",
						],
						"correct": 0,
						"explanation": "A bus topology connects every device to one shared line.",
						"hint": "Think about one long line everyone taps into.",
					},
					{
						"question": "A challenge with bus topology is...",
						"options": [
							"If the main line breaks, the whole network can be affected",
							"It's the fastest topology always",
							"It never breaks",
							"It requires no cable",
						],
						"correct": 0,
						"explanation": "The single shared line is a weak point for the whole network.",
						"hint": "Think about what all the devices depend on.",
					},
					{
						"question": "Bus topology is generally considered...",
						"options": [
							"Simple but with a single main line as a weak point",
							"Impossible to build",
							"Always wireless",
							"The newest technology",
						],
						"correct": 0,
						"explanation": "It's simple to build, but the shared line is a single point of failure.",
						"hint": "Think about the trade-off between simplicity and risk.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how network layouts have changed over time.",
				"questions": [
					{
						"question": "Early small office networks often used simple topologies like...",
						"options": [
							"Bus or ring",
							"Only satellites",
							"Only fiber to the moon",
							"None at all",
						],
						"correct": 0,
						"explanation": "Bus and ring were common simple layouts in early networks.",
						"hint": "Think about the simplest shapes covered in this chapter.",
					},
					{
						"question": "Star topology with a central switch became popular because it...",
						"options": [
							"Made it easier to manage and expand networks",
							"Removed all cables",
							"Was the very first network ever",
							"Requires no hub",
						],
						"correct": 0,
						"explanation": "A central switch makes managing and expanding a network easier.",
						"hint": "Think about how easy a star is to grow.",
					},
					{
						"question": "Today, most home and office networks use a topology similar to...",
						"options": [
							"Star, through a router or switch",
							"Pure ring only",
							"Pure bus only",
							"No topology at all",
						],
						"correct": 0,
						"explanation": "Most modern networks are built around a central router or switch.",
						"hint": "Think about your own home router.",
					},
				],
			},
		},
	},
	9: {
		"title": "First in Line",
		"topic": "Priorities",
		"summary": [
			"• Main: learn about QoS, priority lanes, then set the priorities",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "Dispatcher 201 needs your help. An emergency call keeps getting delayed by regular traffic.",
			},
			{
				"speaker": "Dispatcher 201",
				"text": "Every second matters on an ambulance call, Trainee. We need urgent traffic to go first, without shutting everyone else out.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Let's learn about priorities, then set things up so emergencies always get through.",
			},
		],
		"outro": [
			{
				"speaker": "Dispatcher 201",
				"text": "The alert went through instantly this time. Thank you, Trainee.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Excellent. You've learned nearly every piece of this city's network now, which is good, because something big just happened.",
			},
		],
		"outro_by_stars": {
			1: "Emergency traffic gets through now. Side quests are still open whenever you like.",
			2: "Nice work! A couple of side quests are still waiting.",
			3: "You balanced urgent and everyday traffic perfectly. Well done, Trainee.",
		},
		"main": [
			{
				"id": "what_is_qos",
				"title": "What is QoS?",
				"desc": "Learn that QoS decides which traffic goes first when a network is busy.",
			},
			{
				"id": "priority_lanes",
				"title": "Priority lanes",
				"desc": "Learn how priority works like a fast lane for urgent traffic.",
			},
			{
				"id": "set_the_priorities",
				"title": "Set the priorities",
				"desc": "Decide which traffic should go first at the hospital.",
			},
		],
		"side": [
			{
				"id": "emergency_first",
				"title": "Emergency first",
				"desc": "Learn why emergency calls deserve top priority.",
				"needs_puzzle": false,
				"unlock_after": "what_is_qos",
			},
			{
				"id": "everyday_traffic",
				"title": "Everyday traffic",
				"desc": "Learn what happens to regular traffic under QoS.",
				"needs_puzzle": false,
				"unlock_after": "priority_lanes",
			},
			{
				"id": "fair_or_first",
				"title": "Fair or first?",
				"desc": "Learn that priority isn't about blocking everyone else.",
				"needs_puzzle": false,
				"unlock_after": "set_the_priorities",
			},
			{
				"id": "history",
				"title": "History corner",
				"desc": "Three quick questions about how QoS became necessary.",
				"needs_puzzle": false,
			},
		],
		"terms": {
			"what_is_qos": {
				"title": "Quality of Service (QoS)",
				"text": "QoS decides which traffic gets to go first when a network is busy.",
			},
			"priority_lanes": {
				"title": "Priority",
				"text": "Priority traffic is handled first, similar to a fast lane for emergency vehicles.",
			},
			"set_the_priorities": {
				"title": "Traffic priority",
				"text": "Traffic priority is the order in which different kinds of traffic are handled.",
			},
		},
		"quiz_sets": {
			"what_is_qos": {
				"title": "What is QoS?",
				"done": "You understand what QoS is for.",
				"questions": [
					{
						"question": "Quality of Service (QoS) mainly helps decide...",
						"options": [
							"Which traffic gets to go first when the network is busy",
							"The color of the cables",
							"The price of internet",
							"The size of a building",
						],
						"correct": 0,
						"explanation": "QoS manages which traffic is handled first during busy periods.",
						"hint": "Think about a busy moment where several things need to happen at once.",
					},
					{
						"question": "QoS is most useful when...",
						"options": [
							"The network is busy and multiple things need to go through at once",
							"There is only one device online",
							"The internet is turned off",
							"Nobody is using the network",
						],
						"correct": 0,
						"explanation": "QoS matters most when there's competition for limited capacity.",
						"hint": "Think about when priority actually makes a difference.",
					},
					{
						"question": "Without QoS, urgent traffic and regular traffic...",
						"options": [
							"Compete equally, which can delay urgent traffic",
							"Always separate on their own",
							"Never happen at the same time",
							"Automatically prioritize themselves",
						],
						"correct": 0,
						"explanation": "Without QoS, urgent traffic has no advantage over regular traffic.",
						"hint": "Think about what happens if nothing gives priority to anything.",
					},
				],
			},
			"priority_lanes": {
				"title": "Priority lanes",
				"done": "You understand how priority lanes work.",
				"questions": [
					{
						"question": "QoS priority lanes work a bit like...",
						"options": [
							"A fast lane for emergency vehicles on a road",
							"A parking lot",
							"A closed road",
							"A one-way street only",
						],
						"correct": 0,
						"explanation": "Priority traffic gets to move ahead, like an emergency vehicle in a fast lane.",
						"hint": "Think about an ambulance moving through traffic.",
					},
					{
						"question": "Which type of traffic usually deserves the highest priority?",
						"options": [
							"An emergency call",
							"A regular video game download",
							"A social media scroll",
							"A background update",
						],
						"correct": 0,
						"explanation": "Emergency traffic usually needs to go first.",
						"hint": "Think about what can't afford to wait.",
					},
					{
						"question": "Giving priority to urgent traffic means other traffic...",
						"options": [
							"May wait a little longer, but still gets through",
							"Is deleted forever",
							"Gets a discount",
							"Becomes wireless",
						],
						"correct": 0,
						"explanation": "Other traffic is delayed slightly, not removed.",
						"hint": "Think about what 'priority' really means for everyone else.",
					},
				],
			},
			"set_the_priorities": {
				"title": "Set the priorities",
				"done": "You can set sensible priorities for competing traffic.",
				"questions": [
					{
						"question": "Dispatcher 201 needs to send an emergency alert while others stream and game. What should get top priority?",
						"options": [
							"The emergency alert",
							"The livestream",
							"The game download",
							"None of them",
						],
						"correct": 0,
						"explanation": "The emergency alert should be handled first.",
						"hint": "Think about what can't afford any delay.",
					},
					{
						"question": "If everything has equal priority during a busy moment, what might happen to the emergency alert?",
						"options": [
							"It could be delayed by other traffic",
							"It always finishes first automatically",
							"It disappears",
							"It becomes faster",
						],
						"correct": 0,
						"explanation": "Without priority, urgent traffic has no advantage and can be delayed.",
						"hint": "Think about what happens without any priority rules.",
					},
					{
						"question": "After the emergency traffic is handled, what happens to the other traffic?",
						"options": [
							"It continues normally, just slightly delayed",
							"It's deleted",
							"It's blocked forever",
							"It becomes emergency traffic too",
						],
						"correct": 0,
						"explanation": "Other traffic resumes normally once the urgent traffic is handled.",
						"hint": "Think about what happens right after the priority traffic finishes.",
					},
				],
			},
			"emergency_first": {
				"title": "Emergency first",
				"done": "You know why emergency traffic deserves priority.",
				"questions": [
					{
						"question": "Why should ambulance dispatch calls get priority over entertainment traffic?",
						"options": [
							"Delays could affect someone's safety",
							"Entertainment is always more important",
							"There's no real difference",
							"Priority doesn't matter here",
						],
						"correct": 0,
						"explanation": "Delays in an emergency can have serious consequences.",
						"hint": "Think about what's actually at stake.",
					},
					{
						"question": "A hospital's network giving priority to emergency calls is an example of...",
						"options": [
							"Giving critical traffic priority",
							"Blocking all other traffic",
							"Turning off Wi-Fi",
							"Removing bandwidth",
						],
						"correct": 0,
						"explanation": "This is a real example of QoS in action.",
						"hint": "Think back to what QoS actually does.",
					},
					{
						"question": "True or false: QoS priority means non-emergency traffic is permanently blocked.",
						"options": [
							"False",
							"True",
						],
						"correct": 0,
						"explanation": "Priority traffic goes first, but other traffic still gets through.",
						"hint": "Think about what happens to traffic that isn't top priority.",
					},
				],
			},
			"everyday_traffic": {
				"title": "Everyday traffic",
				"done": "You know how everyday traffic is treated under QoS.",
				"questions": [
					{
						"question": "Everyday traffic like browsing or streaming usually needs...",
						"options": [
							"Lower priority than urgent traffic, but it still gets through",
							"The highest priority always",
							"To be blocked completely",
							"Nothing at all",
						],
						"correct": 0,
						"explanation": "Everyday traffic can wait a little without being blocked.",
						"hint": "Think about how urgent everyday browsing really is.",
					},
					{
						"question": "If there's no emergency traffic at the moment, everyday traffic...",
						"options": [
							"Can use the network normally",
							"Is always blocked",
							"Becomes an emergency",
							"Disappears",
						],
						"correct": 0,
						"explanation": "Without competing urgent traffic, everyday traffic flows normally.",
						"hint": "Think about a quiet moment with no emergencies.",
					},
					{
						"question": "QoS adjusts priority mainly...",
						"options": [
							"When the network is busy and traffic competes",
							"All the time, even with no traffic",
							"Only at night",
							"Never",
						],
						"correct": 0,
						"explanation": "Priority matters most when there's competition for capacity.",
						"hint": "Think about when priority actually changes anything.",
					},
				],
			},
			"fair_or_first": {
				"title": "Fair or first?",
				"done": "You know that QoS is about order, not exclusion.",
				"questions": [
					{
						"question": "QoS priority is mainly about...",
						"options": [
							"Letting urgent traffic go first, not permanently blocking others",
							"Deleting less important traffic",
							"Charging more money",
							"Turning off the internet",
						],
						"correct": 0,
						"explanation": "QoS is about ordering traffic, not eliminating it.",
						"hint": "Think about the difference between 'first' and 'only'.",
					},
					{
						"question": "True or false: giving one type of traffic priority means other traffic never gets through.",
						"options": [
							"False",
							"True",
						],
						"correct": 0,
						"explanation": "Other traffic still gets through, just possibly after a short delay.",
						"hint": "Think about what priority actually guarantees.",
					},
					{
						"question": "A fair QoS setup usually tries to...",
						"options": [
							"Balance urgent needs with everyone still getting service",
							"Block everyone except one person",
							"Remove all traffic",
							"Ignore urgent traffic completely",
						],
						"correct": 0,
						"explanation": "A good setup balances urgency with fairness to everyone.",
						"hint": "Think about balancing two goals at once.",
					},
				],
			},
			"history": {
				"title": "History corner",
				"done": "You know how QoS became a necessary part of networks.",
				"questions": [
					{
						"question": "Early simple networks generally...",
						"options": [
							"Treated all traffic the same, without priority",
							"Already had full QoS everywhere",
							"Only allowed emergency calls",
							"Had no traffic at all",
						],
						"correct": 0,
						"explanation": "Early networks didn't yet have systems for prioritizing traffic.",
						"hint": "Think about how simple early networks were.",
					},
					{
						"question": "As networks carried more types of traffic, engineers introduced QoS to...",
						"options": [
							"Manage which traffic goes first when busy",
							"Remove all traffic",
							"Make every connection wired",
							"Increase prices only",
						],
						"correct": 0,
						"explanation": "QoS was introduced to manage growing, competing traffic.",
						"hint": "Think about what more traffic types would require.",
					},
					{
						"question": "Today, QoS is commonly used for things like...",
						"options": [
							"Prioritizing video calls or emergency services over less urgent traffic",
							"Blocking the internet entirely",
							"Deciding whether it rains",
							"Painting network towers",
						],
						"correct": 0,
						"explanation": "QoS is widely used to prioritize time-sensitive traffic today.",
						"hint": "Think about real examples like video calls or emergency services.",
					},
				],
			},
		},
	},
	10: {
		"title": "The Big Fix",
		"topic": "Troubleshooting",
		"summary": [
			"• Main: read the symptoms, find the cause, then fix the city",
			"• Optional side quests earn extra stars. No timer, no penalties.",
		],
		"outro_speaker": "Mayor Santos",
		"puzzle": {
			"main_quest": "fix_the_city",
			"budget_quest": "budget",
			"notes_quest": "ask_around",
		},
		"intro": [
			{
				"speaker": "Mayor Santos",
				"text": "Trainee, the whole city just went dark again. Every district, all at once.",
			},
			{
				"speaker": "Technician Vic",
				"text": "This isn't like before. This could be anything: a device, a broken path, overloaded bandwidth, even a security issue.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "You've learned every piece of this puzzle across nine chapters. Now put it all together.",
			},
			{
				"speaker": "Technician Vic",
				"text": "Let's start the way any good technician does. By reading the symptoms.",
			},
		],
		"outro": [
			{
				"speaker": "Technician Vic",
				"text": "That's the last fix, Trainee. Every district is stable now.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "From that very first call at the clinic to fixing this citywide outage, you've learned how a real network holds together.",
			},
			{
				"speaker": "Mayor Santos",
				"text": "Relay City is fully connected now. Anything you build from here, you build because you understand how it all works.",
			},
		],
		"outro_by_stars": {
			1: "The city is stable again. A few side quests are still open whenever you want that extra shine.",
			2: "Great work, Trainee. Relay City runs smoothly thanks to you.",
			3: "You found everything there was to learn. Relay City couldn't have restored its network without you.",
		},
		"main": [
			{
				"id": "read_the_symptoms",
				"title": "Read the symptoms",
				"desc": "Learn to notice what's actually going wrong before acting.",
			},
			{
				"id": "find_the_cause",
				"title": "Find the cause",
				"desc": "Narrow down what's likely causing the outage.",
			},
			{
				"id": "fix_the_city",
				"title": "Fix the city",
				"desc": "Restore every building's connection across the block.",
				"kind": "puzzle",
			},
		],
		"side": [
			{
				"id": "ask_around",
				"title": "Ask around",
				"desc": "Tap each building and hear how the outage affected them.",
				"needs_puzzle": true,
				"unlock_after": "fix_the_city",
				"show_notes_progress": true,
			},
			{
				"id": "budget",
				"title": "Lean network",
				"desc": "Fix the city using as few towers as you can.",
				"needs_puzzle": true,
				"unlock_after": "fix_the_city",
				"show_budget": true,
			},
			{
				"id": "step_by_step",
				"title": "Step by step",
				"desc": "Learn a sensible order for troubleshooting any problem.",
				"needs_puzzle": false,
				"unlock_after": "find_the_cause",
			},
			{
				"id": "graduation",
				"title": "Graduation quiz",
				"desc": "A quick recap of everything you've learned across all ten chapters.",
				"needs_puzzle": false,
			},
		],
		"notes": {
			"Building2": {
				"speaker": "Aling Rosa",
				"line": "Everything came back online at once. What a relief, Trainee.",
				"title": "Aling Rosa",
				"text": "A citywide outage can have many small causes working together.",
			},
			"Apartments2": {
				"speaker": "Kuya Migs",
				"line": "The harbor radio is steady again. You really did learn it all.",
				"title": "Kuya Migs",
				"text": "Good troubleshooting checks power, connections, and settings in order.",
			},
			"Apartments3": {
				"speaker": "Ate Joy",
				"line": "Classes are back on. Thank you for sticking with it, Trainee.",
				"title": "Ate Joy",
				"text": "Reading the symptoms carefully helps you find the real cause faster.",
			},
			"Apartments4": {
				"speaker": "Mang Tonio",
				"line": "Every device in my shop is working again. You've come a long way.",
				"title": "Mang Tonio",
				"text": "Sometimes a fix from an earlier lesson, like a device or a route, solves a new problem too.",
			},
		},
		"terms": {
			"read_the_symptoms": {
				"title": "Symptom",
				"text": "A symptom is a sign of a problem, like no light, no signal, or a slow connection.",
			},
			"find_the_cause": {
				"title": "Root cause",
				"text": "The root cause is the real reason behind a problem, not just its symptom.",
			},
			"fix_the_city": {
				"title": "Troubleshooting",
				"text": "Troubleshooting is the process of finding and fixing the cause of a problem, step by step.",
			},
		},
		"quiz_sets": {
			"read_the_symptoms": {
				"title": "Read the symptoms",
				"done": "You know how to read the symptoms of a problem.",
				"questions": [
					{
						"question": "A good first step in troubleshooting is to...",
						"options": [
							"Notice what's actually going wrong (the symptoms)",
							"Immediately replace every device",
							"Ignore the problem",
							"Turn off the whole city",
						],
						"correct": 0,
						"explanation": "Observing symptoms first helps you understand the real problem.",
						"hint": "Think about what a doctor does before treating a patient.",
					},
					{
						"question": "If a router's power light is off, what does that symptom suggest?",
						"options": [
							"It might have no power",
							"It has too much bandwidth",
							"It has perfect signal",
							"It is up to date",
						],
						"correct": 0,
						"explanation": "Recall Chapter 2's lesson on reading a device's lights.",
						"hint": "Think about what a power light usually shows.",
					},
					{
						"question": "If everyone in one area has no signal, but the rest of the city works fine, what does that suggest?",
						"options": [
							"The problem is likely local to that area",
							"The whole internet is gone forever",
							"Nothing is wrong",
							"Everyone's password is different",
						],
						"correct": 0,
						"explanation": "A localized problem points to a local cause, like a dead zone or broken device.",
						"hint": "Think about what's different about that one area.",
					},
				],
			},
			"find_the_cause": {
				"title": "Find the cause",
				"done": "You can narrow down the likely cause of a problem.",
				"questions": [
					{
						"question": "If devices have power but no internet reaches them, what might be the cause?",
						"options": [
							"A broken path or modem issue",
							"The Wi-Fi password is too long",
							"The building is too colorful",
							"The tower is too tall",
						],
						"correct": 0,
						"explanation": "A broken path or a modem problem can cut off internet access even with power.",
						"hint": "Think back to Chapter 2's devices and Chapter 3's routing.",
					},
					{
						"question": "If everything is slow only when many people are online, the cause is likely...",
						"options": [
							"Congestion, from too much traffic and not enough bandwidth",
							"A broken firewall",
							"A stolen password",
							"A dead tower",
						],
						"correct": 0,
						"explanation": "Congestion from too many users at once matches this symptom.",
						"hint": "Think back to Chapter 4's lesson on bandwidth.",
					},
					{
						"question": "If someone reports strange, unexpected traffic trying to get in, that points to...",
						"options": [
							"A possible security issue",
							"A bandwidth issue",
							"A topology issue",
							"A lag issue",
						],
						"correct": 0,
						"explanation": "Unusual traffic trying to get in points toward a security concern.",
						"hint": "Think back to Chapter 7's lesson on threats.",
					},
				],
			},
			"step_by_step": {
				"title": "Step by step",
				"done": "You know a sensible order for troubleshooting any problem.",
				"questions": [
					{
						"question": "A helpful troubleshooting order is often...",
						"options": [
							"Check power, then connections, then settings",
							"Replace everything immediately, no checking",
							"Ignore it and hope it fixes itself",
							"Only ever blame the password",
						],
						"correct": 0,
						"explanation": "Working through basics in order avoids missing an easy fix.",
						"hint": "Think about starting simple before assuming something complex.",
					},
					{
						"question": "If checking power and connections doesn't solve it, a reasonable next step is...",
						"options": [
							"Check the settings or configuration",
							"Give up immediately",
							"Delete the whole network",
							"Buy a completely new city",
						],
						"correct": 0,
						"explanation": "Settings are a common next place to check after the basics.",
						"hint": "Think about what else could be misconfigured.",
					},
					{
						"question": "If you're truly stuck after trying the basics, it's reasonable to...",
						"options": [
							"Ask for help or check documentation",
							"Never ask anyone, ever",
							"Assume it's unfixable",
							"Blame the weather only",
						],
						"correct": 0,
						"explanation": "Asking for help is a normal, sensible part of troubleshooting.",
						"hint": "Think about what a good technician does when stuck.",
					},
				],
			},
			"graduation": {
				"title": "Graduation quiz",
				"done": "You've reviewed the whole journey, from your first call to this citywide fix.",
				"questions": [
					{
						"question": "What carries a message across a network?",
						"options": [
							"The medium",
							"The bandwidth",
							"The topology",
							"The priority",
						],
						"correct": 0,
						"explanation": "From Chapter 1: the medium is what carries the message, like a cable or radio waves.",
						"hint": "Think back to your very first lesson.",
					},
					{
						"question": "What do we call each stop a message makes along its path?",
						"options": [
							"A hop",
							"A hobby",
							"A holiday",
							"A hotel",
						],
						"correct": 0,
						"explanation": "From Chapter 3: each stop along a path is called a hop.",
						"hint": "Think back to routing.",
					},
					{
						"question": "What blocks harmful traffic while letting good traffic through?",
						"options": [
							"A firewall",
							"A topology",
							"A priority lane",
							"A hop",
						],
						"correct": 0,
						"explanation": "From Chapter 7: a firewall filters traffic.",
						"hint": "Think back to security.",
					},
					{
						"question": "Which topology connects every device to one central hub?",
						"options": [
							"Star",
							"Ring",
							"Bus",
							"None",
						],
						"correct": 0,
						"explanation": "From Chapter 8: a star topology connects everything to one hub.",
						"hint": "Think back to the shapes of a network.",
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
