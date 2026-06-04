return {
    sword={type="sword",damage_type="physical",wait=90,power=1.0, repeat_count=2},
    dagger={type="dagger",damage_type="physical",wait=60,power=0.5, repeat_count=1},
    staff={type="staff",damage_type="magic",wait=60,power=0.5, repeat_count=1},
    book={type="book",damage_type="magic",wait=90,power=1.0, repeat_count=2},
    axe={type="axe",damage_type="physical",wait=90,power=1.2, repeat_count=0, condition="wait_stunned", second_only=true},
    crystal={type="crystal",damage_type="magic",wait=90,power=1.2, repeat_count=0, condition="wait_stunned", second_only=true}
}
