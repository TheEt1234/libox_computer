globals = {
    "libox_computer",
    "libox" -- we need to do libox.coroutine.active_sandboxes[id] = nil
}
read_globals = {
    "minetest","vector", "ItemStack",
    "mesecon", "pipeworks", "digilines", "fakelib",
    "table", "dump",
    "wrench", "metatool"
}
ignore = {
    "631" -- line too long
}