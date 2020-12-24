<<<<<<< HEAD
extends Node


var shown = {}

func _ready():
	self.declare_showables(get_tree().current_scene)


func _store(store):
	store.showable_shown = self.shown

func _restore(store):
	var to_hide = self.shown.duplicate()
	for k in shown.keys():
		if k in store.showable_shown:
			to_hide.erase(k)
	self.shown = store.showable_shown
	
	if store.current_scene != Rakugo.SceneLoader.current_scene:
		yield(Rakugo.SceneLoader, "scene_loaded")
	
	for k in to_hide.keys():
		hide(k)
	for k in self.shown.keys():
		show(k, self.shown[k])

func declare_showables(node:Node=get_tree().get_root()):
	declare_showables_recursively(node)


func declare_showables_recursively(node):
	for n in node.get_children():
		declare_showables_recursively(n)

	var groups = node.get_groups().duplicate()
	for g in groups:
		if g.begins_with("showable "):
			node.add_to_group(get_showable_group_tag(g, true))


func get_showable_group_tag(group, keep_prefix=false):
	group = group.trim_prefix("showable ")
	if keep_prefix:
		return "showable " + group.split(' ', false, 1)[0] + " _"
	return group.split(' ', false, 1)[0] + " _"


func parse_showable_tag(tag, keep_prefix=false):
	tag = tag.trim_prefix("showable ")
	
	var prefix = ""
	if keep_prefix:
		prefix = "showable "
	
	var output = []
	var tags = tag.split(' ', false)
	var tmp_tag = prefix
	for t in tags:
		tmp_tag += t
		output.append(tmp_tag)
		tmp_tag += ' '
	return output


func show(showable_tag, args):
	showable_tag = showable_tag.trim_prefix("showable ")
	var group_tag = get_showable_group_tag(showable_tag, true)
	var tags = parse_showable_tag(showable_tag, true)
	for i in tags.size() - 1:#only postfix with wildcard non-exact matches
		tags[i] = tags[i]+" *"
	tags.invert()#invert to have the exact tag first
	
	
	var is_any_shown = false
	for t in tags:
		if get_tree().get_nodes_in_group(t):
			is_any_shown = true
			break
	
	if is_any_shown:
		remove_from_shown(group_tag)
		self.shown[showable_tag] = args
		
		var is_shown
		for n in get_tree().get_nodes_in_group(group_tag):
			is_shown = false
			for t in tags:
				if n.is_in_group(t):
					is_shown = true
					break
			if is_shown:
				show_showable(n, showable_tag, args)
			else:
				n.hide()


func show_showable(node, tag, args):
	if node.has_method("_show"):
		node._show(tag, args)
	elif node.has_method("show"):
		node.show()
	else:
		push_error(str("Node ", node, " tagged ", tag, " is not showable."))


func hide(showable_tag):
	showable_tag = "showable " + showable_tag.trim_prefix("showable ")
	var group_tag = get_showable_group_tag(showable_tag, true)
	
	var to_hide = remove_from_shown(showable_tag)
	if group_tag == showable_tag + " _":
		to_hide.append(group_tag)

	for t in to_hide:
		for n in get_tree().get_nodes_in_group(t):
			if n.has_method('hide'):
				n.hide()
	
func remove_from_shown(tag):
	tag = tag.trim_prefix("showable ").trim_suffix(" _")
	var removed = [tag]
	self.shown.erase(tag)

	var old_shown = self.shown.duplicate()
	for k in old_shown.keys():
		if k.begins_with(tag + " "):
			removed.append(k)
			self.shown.erase(k)

	return removed
	
=======
extends Node


var shown = {}

func _ready():
	self.declare_showables()


func _store(store):
	store.showable_shown = self.shown

func _restore(store):
	var to_hide = self.shown.duplicate()
	for k in shown.keys():
		if k in store.showable_shown:
			to_hide.erase(k)
	self.shown = store.showable_shown

	if store.current_scene != Rakugo.SceneLoader.current_scene:
		yield(Rakugo.SceneLoader, "scene_loaded")

	for k in to_hide.keys():
		hide(k)
	for k in self.shown.keys():
		show(k, self.shown[k])


func declare_showables():
	for n in get_tree().get_nodes_in_group("showable"):
		var current_tags = {}
		for g in n.get_groups():
			if g.begins_with("$ "):
				current_tags[g] = true

		var temp_tags = {}
		for t in current_tags.keys():
			if "#" in t:
				t = t.replace('#', n.get_name())
			t = t.to_lower()
			temp_tags[get_radical_tag(t)] = true
			temp_tags[t] = true

		for t in temp_tags.keys():
			n.add_to_group(t)


func get_radical_tag(tag):
	tag = tag.trim_prefix("$ ")
	var tag_components = tag.split(' ', false, 1)
	if tag_components:
		return "$ " + tag_components[0] + " _"
	return ""


func get_tags_to_show(tag):
	var to_show = [tag]
	tag = tag.trim_prefix("$ ")

	var tag_components = tag.split(' ', false, 1)
	tag_components.remove(tag_components.size() - 1)

	var composite = ""
	for c in tag_components:
		composite = composite + " " + c
		to_show.append("$" + composite + " *")
	return to_show


func remove_from_shown(tag): # This function pulls double-duty, as it both clean the shown dict and returns a list of tags to hide
	tag = tag.trim_prefix("$ ").trim_suffix(" _")
	var removed = [tag]
	self.shown.erase(tag)# Erasing exact tag

	var old_shown = self.shown.duplicate()
	for k in old_shown.keys():
		if k.begins_with(tag + " "): # Erasing tags starting by but longer than the tag
			removed.append(k)
			self.shown.erase(k)

	return removed


func show(tag, args):
	tag = "$ " + tag.trim_prefix("$ ")
	var radical_tag = get_radical_tag(tag)
	var to_show = get_tags_to_show(tag)

	var shown_any = false
	for t in to_show:
		if get_tree().get_nodes_in_group(t):
			shown_any = true
			break

	if shown_any:
		remove_from_shown(radical_tag)
		self.shown[tag] = args

		var is_shown
		for n in get_tree().get_nodes_in_group(radical_tag):
			is_shown = false
			for t in to_show:
				if n.is_in_group(t):
					is_shown = true
					break
			if is_shown:
				show_showable(n, tag, args)
			else:
				n.hide()

func show_showable(node, tag, args):
	if node.has_method("_show"):
		node._show(tag, args)
	elif node.has_method("show"):
		node.show()
	else:
		push_error(str("Node ", node, " tagged ", tag, " is not showable."))


func hide(tag):
	tag = "$ " + tag.trim_prefix("$ ")
	var radical_tag = get_radical_tag(tag)
	var to_hide = remove_from_shown(tag)

	if radical_tag.trim_suffix(" _") == tag.trim_suffix(" _"): # Hide all
		to_hide.append(radical_tag)

	for t in to_hide:
		for n in get_tree().get_nodes_in_group(t):
			if n.has_method('hide'):
				n.hide()
>>>>>>> f4a81ea87c9bba54a08d3ac43a556af80a7ac575
