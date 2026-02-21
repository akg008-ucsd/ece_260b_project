export PROJ_DIR=`pwd`
export DESIGN_DIR="$PROJ_DIR/design"
export VERIF_DIR="$PROJ_DIR/verif"
alias design="cd $DESIGN_DIR"
alias verif="cd $VERIF_DIR"
alias iveri="iverilog -o compiled -c"
alias irun="vvp -l isim.log compiled"
alias wave="gtkwave"
