# Practical-Byzantine-Fault-Tolerance-Project

note:

now merged to the main branch. the name of this application has been changed from Lab3 to PBFT, and the deps were deleted and refetched.
start from the branch of change-deps

TODO: We still need to decide the content/format of different messages and PBFT state itself.

Then we can implement the functions and codes,

and test it.

Then add digital signatures. Before this step every signature check can pass.

Then add view changing.

Note: There is no election, so everything about election in Raft is useless. Instead, when a primary fails, the NEXT
replica becomes primary.

I think the "sequence number" is just an integer.