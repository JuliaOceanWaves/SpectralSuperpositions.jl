using Test
using RepoTemplate

greet_string = "Friend"

@test greet() == "Hello, world!"
@test greet(greet_string) == "Hello, Friend!"
