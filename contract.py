from pyteal import *

def george_interact():
    on_init = Seq([
        App.globalPut(Bytes("Creator"), Txn.sender()),  # save the creator's address
        App.globalPut(Bytes("health"), Int(5)),         # set an integer to 5
        Return(Int(1)),
    ])

    is_creator = Txn.sender() == App.globalGet(Bytes("Creator"))
    
    on_leave = Seq([Return(Int(1))])
    on_join = Seq([Return(Int(1))])

    on_damage = Seq([
        # check if npc is dead or fully replenished
        If(Or(App.globalGet(Bytes("health")) >= Int(10), 
              App.globalGet(Bytes("health")) <= Int(0)), Return(Int(0))), 

        # update health
        App.globalPut(Bytes("health"), App.globalGet(Bytes("health")) - Int(1)),
        Return(Int(1)),
    ])

    on_heal = Seq([
        # check if npc is dead or fully replenished
        If(Or(App.globalGet(Bytes("health")) >= Int(10), 
              App.globalGet(Bytes("health")) <= Int(0)), Return(Int(0))), 

        App.globalPut(Bytes("health"), App.globalGet(Bytes("health")) + Int(1)),
        Return(Int(1)),
    ])

    program = Cond(
        [Txn.application_id() == Int(0), on_init],                                  # init
        [Txn.on_completion() == OnComplete.DeleteApplication, Return(is_creator)],  # delete
        [Txn.on_completion() == OnComplete.UpdateApplication, Return(is_creator)],  # update
        [Txn.on_completion() == OnComplete.CloseOut, on_leave],                     # leave
        [Txn.on_completion() == OnComplete.OptIn, on_join],                         # join
        [Txn.application_args[0] == Bytes("heal"), on_heal],                        # heal
        [Txn.application_args[0] == Bytes("damage"), on_damage],                    # damage
    )

    return program

def clear_state():
    program = Seq([Return(Int(1))])
    return program

if __name__ == "__main__":
    with open('build/george_interact.teal', 'w') as f:
        compiled = compileTeal(george_interact(), mode=Mode.Application, version=2)
        f.write(compiled)

    with open('build/clear_state.teal', 'w') as f:
        compiled = compileTeal(clear_state(), mode=Mode.Application, version=2)
        f.write(compiled)

