-- data/accessory.lua: アクセサリー定義データを提供する責務。
return {

    goggles={
        resist={type="blind",value=0.5}
    },

    flash={
        inflict={type="blind",value=20},
        special={condition="stun",weapon_type="any"}
    },

    stun_guard={
        resist={type="stun",value=0.5}
    },

    finisher={
        special={condition="wait_stunned",weapon_type="any"}
    },

    final_action={
        special={condition="final_action",weapon_type="any"}
    },

    sword_special={
        special={condition="stun",weapon_type="sword"}
    },

    dagger_special={
        special={condition="stun",weapon_type="dagger"}
    },

    staff_special={
        special={condition="stun",weapon_type="staff"}
    },

    book_special={
        special={condition="stun",weapon_type="book"}
    }
}
