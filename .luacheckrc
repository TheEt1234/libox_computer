globals = {
    "libox_computer",
    "libox" -- we need to do libox.coroutine.active_sandboxes[id] = nil
}
read_globals = {
    "minetest","vector", "ItemStack",
    "mesecon", "pipeworks", "digilines"
}
ignore = {
    "631" -- line too long
}