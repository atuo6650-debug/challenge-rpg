-- data/enemy.lua: 主人公や敵の初期ステータス・装備データを提供する責務。


return {

    hero={
        name="Hero",
        vitality=30,strength=24,magic=18,focus=16,spirit=12,
        w1="sword",w2="dagger",
        a1="heal",a2="counter_sword",
        acc1="flash",acc2="finisher",
        special_condition="stun"
    },

    enemy={
        name="Enemy",
        vitality=26,strength=18,magic=14,focus=16,spirit=14,
        w1="dagger",w2="dagger",
        a1="counter_dagger",a2="counter_dagger",
        acc1="stun_guard",acc2="goggles"
    }
}
