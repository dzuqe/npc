from pyteal import *

def george_interact():
    on_init = Seq([
        App.globalPut(Bytes("george"), Txn.sender()),  # save the creator's address
        App.globalPut(Bytes("health"), Int(5)),         # set an integer to 5
        Return(Int(1)),
    ])

    is_creator = Txn.sender() == App.globalGet(Bytes("george"))
    
    # opt in or out
    on_leave = Seq([Return(Int(1))])
    on_join = Seq([Return(Int(1))])

    # check if 2nd tx amount is correct
    # and that george receives the payment
    correct_amt_for_george = If(Or(Gtxn[1].amount() < Int(5000000),
            Gtxn[1].receiver() != App.globalGet(Bytes("george"))),
            Return(Int(0)))

    # check if npc is dead or fully replenished
    alive_or_dead = If(Or(App.globalGet(Bytes("health")) >= Int(10), 
            App.globalGet(Bytes("health")) <= Int(0)), Return(Int(0)))

    on_damage = Seq([
        alive_or_dead,
        correct_amt_for_george,
        App.globalPut(Bytes("health"), App.globalGet(Bytes("health")) - Int(1)),
        Return(Int(1)),
    ])

    on_heal = Seq([
        alive_or_dead,
        correct_amt_for_george,
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

