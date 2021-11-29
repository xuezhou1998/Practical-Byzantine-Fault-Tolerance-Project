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

I strongly suggest we delete the "create account" function before the system somehow works. ok, good.

from my understanding, during the tesing, in initialization phase, the primary and replicas will initialize with a set of public keys of every server, including all clients' public keys 

i have read the section 4 of the paper.

i added new() methods for the messages from preprepare to reply

i changed the integer type into non-neg-integer type
