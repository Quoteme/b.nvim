machine Lift

variables floor door requests

invariants
  @floor_type floor ∈ 0 ‥ 3
  @door_type door ∈ BOOL
  @requests_type requests ⊆ 0 ‥ 3
  @safe door = TRUE ⇒ floor ∉ requests

events
  event INITIALISATION
    then
      @act1 floor ≔ 0
      @act2 door ≔ FALSE
      @act3 requests ≔ ∅
  end

  event call
    any f
    where
      @grd1 f ∈ 0 ‥ 3
      @grd2 f ∉ requests
      @grd3 f ≠ floor ∨ door = FALSE
    then
      @act1 requests ≔ requests ∪ {f}
  end

  event move
    any f
    where
      @grd1 f ∈ requests
      @grd2 door = FALSE
      @grd3 f ≠ floor
    then
      @act1 floor ≔ f
  end

  event open
    when
      @grd1 door = FALSE
      @grd2 floor ∈ requests
    then
      @act1 door ≔ TRUE
      @act2 requests ≔ requests ∖ {floor}
  end

  event close
    when
      @grd1 door = TRUE
    then
      @act1 door ≔ FALSE
  end
end
